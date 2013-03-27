#!/usr/bin/python2

import pydot
import pymongo

client = pymongo.Connection('localhost', 3002)
db = client[u"meteor"]
relations = db[u"relations"]
users = db[u"users"]

graph = pydot.Dot(graph_type="graph")

def email(id):
    return users.find_one(id)["emails"][0]["address"]


for relation in relations.find():
    print relation
    edge = pydot.Edge(
            email(relation["user_ids"][0]),
            email(relation["user_ids"][1]),
            weight=int(relation["weight"] * 100),
            label=str({0:.2}).format(relation["weight"]),
            penwidth=float(relation["weight"]) * 5)
    graph.add_edge(edge)

graph.write_png("./graph_visualization.png")
