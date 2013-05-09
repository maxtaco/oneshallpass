var engine_opts = {
  net: {
    url_prefix: "https://oneshallpass.com"
  }
};

chrome.tabs.getSelected(function(tab) {
  var m = tab.url.match(/.+:\/\/([a-zA-Z0-9.]+)/);
  var domain = m[1];
  $('#input-host').val(domain);
  fe.input_host_event();
});