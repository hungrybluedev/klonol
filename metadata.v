module main

import v.vmod

const manifest = vmod.from_file('v.mod') or { panic(err) }

pub const (
	version      = manifest.version
	name         = manifest.name
	description  = manifest.description
	instructions = '
klonol requires Access Tokens to work properly. Refer to README for more
information. It retrieves information about ALL available repositories
belonging to the authenticated user. Both public and private.

Please follow safety precautions when storing access tokens, and read
the instructions carefully.
'
)
