import webapp2

def fetch_file (f) :
    fh = open (f, "r")
    return fh.read()

class MainPage(webapp2.RequestHandler):
    def get (self):
        self.response.headers['Content-Type'] = "text/html"
        self.response.out.write(fetch_file("index.html"))

app = webapp2.WSGIApplication([('/', MainPage)], debug=True)
