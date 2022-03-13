module common

import net.http

pub fn is_access_token_valid(access_token string, endpoint_url string) bool {
	mut request := http.Request{
		url: endpoint_url
		method: .get
	}
	request.add_header(.authorization, 'token $access_token')
	result := request.do() or { return false }
	return result.status_code == 200
}
