#!/bin/sh

mongosh mongodb://127.0.0.1:27017/admin --eval 'db.shutdownServer()'
