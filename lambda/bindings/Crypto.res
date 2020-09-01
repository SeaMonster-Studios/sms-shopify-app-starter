type t = string

@bs.module("crypto")
external createHmac: (string, string) => t = "createHmac"

@bs.send("update") external update: (t, string) => t = ""

@bs.send("digest") external digest: (t, string) => t = ""

@bs.module("crypto")
external timingSafeEqual: (Node.Buffer.t, Node.Buffer.t) => bool = "timingSafeEqual"

@bs.module("crypto") external randomBytes: int => t = "randomBytes"

@bs.send("toString") external toString: (t, string) => string = ""
