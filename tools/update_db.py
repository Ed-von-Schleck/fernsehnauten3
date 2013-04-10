#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import print_function
from __future__ import unicode_literals

import subprocess
import cStringIO as StringIO
from pprint import pprint
import datetime
import time
import argparse
import json
import io
import sys
import urllib

from pymongo import Connection
from bson.objectid import ObjectId

from vendor import xmltv
from vendor import pexpect

REMOTE_URL = None # address as string if deployed 
with io.open("channels.json", encoding="utf-8") as channelfile:
    CHANNELS = json.load(channelfile)

def get_timestamp(dt):
    date = datetime.datetime(int(dt[0:4]), int(dt[4:6]), int(dt[6:8]), int(dt[8:10]), int(dt[10:12]), int(dt[12:14]))
    return int(time.mktime(date.timetuple()))

parser = argparse.ArgumentParser(description="Update channel and program data in fernsehnauten's mongodb database.")
parser.add_argument("-r", "--remote", action="store_true", default=False, help="update the remote deployment")
parser.add_argument("-c", "--clean", action="store_true", default=False, help="clean database before inserting data")
args = parser.parse_args()
mongo_url_command = ["meteor", "mongo", "-U"]
if args.remote:
    mongo_url_command.append("fernsehnauten2.meteor.com")
if REMOTE_URL is not None:
    mongo_url_command.append(REMOTE_URL)

process = pexpect.spawn(" ".join(mongo_url_command))
if args.remote:
    process.expect("Password: ")
    process.sendline("iwascreononce")
process.expect(pexpect.EOF)
mongo_url = process.before.strip()
process.close()
print("using mongodb at:", mongo_url)
if args.remote:
    db = Connection(mongo_url).fernsehnauten2_meteor_com
else:
    db = Connection(mongo_url).meteor

xmltv_file = StringIO.StringIO()
print("downloading data ... ", end="")
sys.stdout.flush()
xmltv_command = ["tools/tv_grab_eu_egon"]
xmltv_str = subprocess.check_output(xmltv_command)
print("done")
xmltv_file = StringIO.StringIO(xmltv_str)

if args.clean:
    print("deleting database entries ... ", end="")
    sys.stdout.flush()
    db.channels.remove()
    db.programs.remove()
    print("done")

print("inserting channels ... ", end="")
sys.stdout.flush()
for channel in xmltv.read_channels(xmltv_file):
    channel["_id"] = channel["id"]
    del channel["id"]
    if not channel["_id"] in CHANNELS:
        continue
    channel["position"] = CHANNELS[channel["_id"]]["position"]
    channel["logo"] = CHANNELS[channel["_id"]]["logo"]
    channel["tags"] = CHANNELS[channel["_id"]]["tags"]
    channel["composite"] = CHANNELS[channel["_id"]]["composite"]
    channel["name"] = channel["display-name"][0][0]
    del channel["display-name"]
    db.channels.save(channel)
print("done")
xmltv_file.seek(0)
print("inserting programs ... ", end="")
sys.stdout.flush()
for program in xmltv.read_programmes(xmltv_file):
    if not program["channel"] in CHANNELS:
        continue
    program["start"] = get_timestamp(program["start"])
    program["stop"] = get_timestamp(program["stop"])
    program["title"] = program["title"][0][0]
    program["_id"] = program["title"].replace(" ", "+") + "_" + unicode(program["start"]) + "_" + unicode(program["stop"])
    existing_program = db.programs.find_one(program["_id"])
    if existing_program is None:
        program["desc"] = program["desc"][0][0] if "desc" in program else None
        if "sub-title" in program:
            program["subtitle"] = program["sub-title"][0][0]
            del program["sub-title"]
        else:
            program["subtitle"] = None
        #program["composite_channel"] = CHANNELS[program["channel"]]["composite"]
        program["channel_ids"] = [program["channel"]]
        del program["channel"]
        db.programs.insert(program)
    else:
        db.programs.update({"_id": program["_id"]}, {"$addToSet": {"channel_ids": program["channel"]}})
        
print("done")

if __name__ == "__main__":
    pass
