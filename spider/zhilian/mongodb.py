

import pymongo

from zhilian.config import *

client = pymongo.MongoClient(MONGO_URI)
db = client[MONGO_DB]

db.drop_collection('大数据')

