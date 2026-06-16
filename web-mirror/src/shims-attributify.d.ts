// Let TSX accept the UnoCSS attributify attributes this app uses (valued,
// string). Explicit list — more reliable than the preset's partial type.
import "react";

declare module "react" {
  interface HTMLAttributes<T> {
    flex?: string;
    grid?: string;
    items?: string;
    justify?: string;
    gap?: string;
    p?: string;
    m?: string;
    w?: string;
    h?: string;
    "max-w"?: string;
    "min-w"?: string;
    text?: string;
    font?: string;
    bg?: string;
    border?: string;
    rounded?: string;
    shadow?: string;
    z?: string;
    inset?: string;
    overflow?: string;
  }
}
