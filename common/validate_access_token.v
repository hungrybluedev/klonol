module common

import net.http

// authorized_get builds a GET request that carries the token in the Authorization header.
// A token in the URL ends up in server and proxy logs.
pub fn authorized_get(url string, access_token string) http.Request {
	mut request := http.Request{
		url:    url
		method: .get
	}
	if access_token != 'unset_value' {
		request.add_header(.authorization, 'token ${access_token}')
	}
	return request
}

pub fn is_access_token_valid(access_token string, endpoint_url string) bool {
	result := authorized_get(endpoint_url, access_token).do() or { return false }
	return result.status_code == 200
}
