module common

fn test_authorized_get_sends_the_token_in_the_header() {
	request := authorized_get('https://git.example.com/api/v1/user', 'secret-token')
	assert (request.header.get(.authorization) or { '' }) == 'token secret-token'
	assert !request.url.contains('secret-token')
}

fn test_authorized_get_skips_the_header_for_an_unset_token() {
	request := authorized_get('https://api.github.com/user/repos', 'unset_value')
	assert request.header.get(.authorization) or { '' } == ''
}
