#!/usr/bin/python2

import BaseHTTPServer

import pydot
import pymongo

client = pymongo.Connection('localhost', 3002)
db = client[u"meteor"]
relations = db[u"relations"]
users = db[u"users"]

def email(id):
    return users.find_one(id)["emails"][0]["address"]

def make_graph():
    graph = pydot.Dot(graph_type="graph")
    for relation in relations.find():
        print relation
        edge = pydot.Edge(
            email(relation["user_ids"][0]),
            email(relation["user_ids"][1]),
            label=str({0:.2}).format(relation["weight"]),
            penwidth=float(relation["weight"]) * 5,
            weight=int(relation["weight"] * 100))
        graph.add_edge(edge)
    return graph

class Handler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_GET(res):
        res.send_response(200)
        res.send_header("Content-type", "text/html")
        res.end_headers()

        res.wfile.write("<!doctype html>")
        res.wfile.write("<html>")
        res.wfile.write("<head>")
        res.wfile.write("<title>")
        res.wfile.write("Fernsehnauten Graph Visualization")
        res.wfile.write("</title>")
        res.wfile.write("</head>")
        res.wfile.write("<body>")
        res.wfile.write("<svg>")
        res.wfile.write(make_graph().create_svg())
        res.wfile.write("</svg>")
        res.wfile.write("</body>")
        res.wfile.write("</html>")

def main():
    graph = make_graph()
    server = BaseHTTPServer.HTTPServer(('localhost', 8080), Handler)
    try:
          server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()

if __name__ == "__main__":
    main()
