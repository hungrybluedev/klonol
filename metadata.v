module main

import v.vmod

// Note: $embed_file resolves relative to this file, so metadata.v must stay next to
// v.mod. Introducing a `base_url` source folder in v.mod would break this embed.
const embedded_vmod = $embed_file('v.mod', .zlib)
const manifest = vmod.decode(embedded_vmod.to_string()) or {
	eprintln('Could not decode the v.mod file. Please restore to original state.')
	exit(1)
}

pub const version = manifest.version
pub const name = manifest.name
pub const description = manifest.description
pub const instructions = '
klonol requires Access Tokens to work properly. Refer to README for more
information. It retrieves information about ALL available repositories
belonging to the authenticated user. Both public and private.

Please follow safety precautions when storing access tokens, and read
the instructions in README carefully.
'
