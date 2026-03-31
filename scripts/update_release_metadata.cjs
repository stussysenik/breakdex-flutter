const fs = require('node:fs');
const path = require('node:path');

const repoRoot = process.cwd();
const pubspecPath = path.join(repoRoot, 'pubspec.yaml');
const changelogPath = path.join(repoRoot, 'CHANGELOG.md');
const targets = [
  path.join(repoRoot, 'README.md'),
  path.join(repoRoot, 'progress.md'),
  path.join(repoRoot, 'docs', 'hyperdata-ledger.md'),
];

const pubspec = fs.readFileSync(pubspecPath, 'utf8');
const changelog = fs.readFileSync(changelogPath, 'utf8');
const pubspecVersion = readPubspecVersion(pubspec);
const releaseVersion = process.argv[2] || pubspecVersion.split('+')[0];
const releaseTag = process.argv[3] || `v${releaseVersion}`;
const refreshedAt = new Date().toISOString().slice(0, 10);
const latestRelease = readLatestRelease(changelog, releaseVersion);

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

for (const filePath of targets) {
  let source = fs.readFileSync(filePath, 'utf8');
  source = replaceMarkedBlock(source, 'meta', metaBlock, filePath);
  source = replaceMarkedBlock(source, 'notes', notesBlock, filePath);
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
