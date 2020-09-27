try {
   shell.connect('mycluster@mysql01', "Cluster^123");
   print(dba.getCluster().status());
   var result = shell.getSession().runSql("SHOW DATABASES;")
   var record = result.fetchOne();
   while(record){
      print(record);
      record = result.fetchOne();
   }
   var result = shell.getSession().runSql("SELECT * FROM performance_schema.replication_group_members;")
   var record = result.fetchOne();
   while(record){
      print(record);
      record = result.fetchOne();
   }
} catch(e) {
     print('\nThe InnoDB cluster could not be accessed.\n\nError: ' +
     + e.message + '\n');
}

