use admin;
db.createUser({user: "admin", pwd: "admin", roles: [ "userAdminAnyDatabase"]})
db.auth("admin","admin")
use dmsrepo;
db.createUser({user:"dmsuser", pwd:"admin", roles:[{role: "readWrite", db: "dmsrepo"}]});
db.auth("dmsuser","admin")
