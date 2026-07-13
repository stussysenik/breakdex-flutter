const fs = require('node:fs');
const path = require('node:path');
const {execSync} = require('node:child_process');

const repoRoot = process.cwd();
const pubspecPath = path.join(repoRoot, 'pubspec.yaml');
const changelogPath = path.join(repoRoot, 'docs', 'CHANGELOG.md');
// Only files that still carry the release:* marker blocks. The 2026-07-06 docs
// consolidation moved VISION/TECHSTACK into docs/, removed PROGRESS.MD, and
// dropped the markers from README/ROADMAP — the old root paths would ENOENT (or
// miss markers) and crash the release on CI. Keep this list in lockstep with the
// files that opt in via <!-- release:meta:start --> blocks.
const targets = [
  path.join(repoRoot, 'docs', 'VISION.MD'),
  path.join(repoRoot, 'docs', 'TECHSTACK.MD'),
  path.join(repoRoot, 'docs', 'hyperdata-ledger.md'),
];

const pubspec = fs.readFileSync(pubspecPath, 'utf8');
const changelog = fs.readFileSync(changelogPath, 'utf8');
const pubspecVersion = readPubspecVersion(pubspec);
const releaseVersion = process.argv[2] || pubspecVersion.split('+')[0];
const releaseTag = process.argv[3] || `v${releaseVersion}`;
const refreshedAt = new Date().toISOString().slice(0, 10);
const latestRelease = readLatestRelease(changelog, releaseVersion);
const gitBranch = readGitBranch();
const gitRevision = safeGit('git rev-parse --short HEAD');
const gitCommit = safeGit('git rev-parse HEAD');
const gitDescribe = safeGit('git describe --tags --always');

const metaBlock = [
  '<!-- release:meta:start -->',
  `- Release tag: \`${releaseTag}\``,
  `- Release version: \`${latestRelease.version}\``,
  `- Pubspec version: \`${pubspecVersion}\``,
  `- Released: \`${latestRelease.releasedAt}\``,
  `- Metadata refreshed: \`${refreshedAt}\``,
  '<!-- release:meta:end -->',
].join('\n');

const notesBlock = [
  '<!-- release:notes:start -->',
  ...latestRelease.notes.map((note) => `- ${note}`),
  '<!-- release:notes:end -->',
].join('\n');

const provenanceBlock = [
  '<!-- release:provenance:start -->',
  `- Source branch: \`${gitBranch}\``,
  `- Source revision: \`${gitRevision}\``,
  `- Source commit: \`${gitCommit}\``,
  `- Source describe: \`${gitDescribe}\``,
  '- Generator: `scripts/update_release_metadata.cjs`',
  '- Inputs: `docs/CHANGELOG.md`, `pubspec.yaml`, and local git metadata',
  '<!-- release:provenance:end -->',
].join('\n');

for (const filePath of targets) {
  let source = fs.readFileSync(filePath, 'utf8');
  source = replaceMarkedBlock(source, 'meta', metaBlock, filePath);
  source = replaceMarkedBlock(source, 'notes', notesBlock, filePath);
  source = replaceMarkedBlock(source, 'provenance', provenanceBlock, filePath);
  fs.writeFileSync(filePath, source);
}

function readPubspecVersion(source) {
  const match = source.match(/^version:\s*([^\s]+)\s*$/m);
  if (!match) {
    throw new Error('Unable to read version from pubspec.yaml');
  }
  return match[1];
}

function readLatestRelease(changelogSource, requestedVersion) {
  const lines = changelogSource.split(/\r?\n/);
  const releases = [];
  let current = null;

  for (const line of lines) {
    const header = parseReleaseHeader(line);
    if (header) {
      if (current) releases.push(current);
      current = {
        version: header.version,
        releasedAt: header.releasedAt,
        body: [],
      };
      continue;
    }

    if (current) current.body.push(line);
  }

  if (current) releases.push(current);

  const matchedRelease =
      releases.find((release) => release.version === requestedVersion) ||
      releases[0];

  if (!matchedRelease) {
    return {
      version: requestedVersion,
      releasedAt: new Date().toISOString().slice(0, 10),
      notes: ['No tagged release notes found yet.'],
    };
  }

  const notes = matchedRelease.body
      .map((line) => line.trim())
      .filter((line) => line.startsWith('* '))
      .map((line) => sanitizeBullet(line.slice(2)))
      .filter(Boolean)
      .slice(0, 5);

  return {
    version: matchedRelease.version,
    releasedAt: matchedRelease.releasedAt,
    notes: notes.length > 0 ? notes : ['No tagged release notes found yet.'],
  };
}

function parseReleaseHeader(line) {
  const linkedMatch = line.match(
      /^#\s+\[(.+?)\]\([^)]+\)\s+\((\d{4}-\d{2}-\d{2})\)\s*$/,
  );
  if (linkedMatch) {
    return {
      version: linkedMatch[1],
      releasedAt: linkedMatch[2],
    };
  }

  const plainMatch = line.match(
      /^#\s+([0-9]+\.[0-9]+\.[0-9]+)\s+\((\d{4}-\d{2}-\d{2})\)\s*$/,
  );
  if (!plainMatch) return null;

  return {
    version: plainMatch[1],
    releasedAt: plainMatch[2],
  };
}

function sanitizeBullet(bullet) {
  return bullet
      .replace(/\s+\(\[[^\]]+\]\([^)]+\)\)\s*$/g, '')
      .replace(/\[@[^\]]+\]\([^)]+\)/g, '')
      .replace(/\s+/g, ' ')
      .trim();
}

function readGitBranch() {
  const githubRefName = process.env.GITHUB_REF_NAME;
  if (githubRefName) return githubRefName;

  const branch = safeGit('git rev-parse --abbrev-ref HEAD');
  return branch || 'HEAD';
}

function safeGit(command) {
  try {
    return execSync(command, {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch (_) {
    return 'unknown';
  }
}

function replaceMarkedBlock(source, markerName, replacement, filePath) {
  const pattern = new RegExp(
      `<!-- release:${markerName}:start -->[\\s\\S]*?<!-- release:${markerName}:end -->`,
  );

  if (!pattern.test(source)) {
    throw new Error(
        `Release ${markerName} markers not found in ${path.relative(repoRoot, filePath)}`,
    );
  }

  return source.replace(pattern, replacement);
}
