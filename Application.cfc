component {
    this.name = "Air District Checklist";
    this.datasource = "air_district"
    this.datasources["air_district"] = {
        class: 'com.mysql.cj.jdbc.Driver'
      , bundleName: 'com.mysql.cj'
      , bundleVersion: '8.0.19'
      , connectionString: 'jdbc:mysql://mysql24.ezhostingserver.com:3306/air_district?characterEncoding=UTF-8&serverTimezone=America/Los_Angeles&maxReconnects=3'
      , username: 'air_district'
      , password: "encrypted:9941df3dcc1cfd8a488ea8e1cfe772b957204b7892e1425af9832cab540f9802"
      
      // optional settings
      , connectionLimit:100 // default:-1
      , alwaysSetTimeout:true // default: false
      , validate:false // default: false
  };
}