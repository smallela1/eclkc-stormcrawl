name: "solr-crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

    - resource: false
      file: "solr-conf.yaml"
      override: true
      
spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.solr.persistence.SolrSpout"
    parallelism: 1

bolts:
  - id: "partitioner"
    className: "com.digitalpebble.stormcrawler.bolt.URLPartitionerBolt"
    parallelism: 1
  - id: "fetcher"
    className: "com.digitalpebble.stormcrawler.bolt.FetcherBolt"
    parallelism: 1
  - id: "sitemap"
    className: "com.digitalpebble.stormcrawler.bolt.SiteMapParserBolt"
    parallelism: 1
  - id: "jsoup"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 5
  - id: "shunt"
    className: "com.digitalpebble.stormcrawler.tika.RedirectionBolt"
    parallelism: 5
  - id: "tika"
    className: "com.digitalpebble.stormcrawler.tika.ParserBolt"
    parallelism: 5        
  - id: "index"
    className: "com.digitalpebble.stormcrawler.solr.bolt.IndexerBolt"
    parallelism: 1
  - id: "status"
    className: "com.digitalpebble.stormcrawler.solr.persistence.StatusUpdaterBolt"
    parallelism: 1


streams:
  - from: "spout"
    to: "partitioner"
    grouping:
      type: SHUFFLE
      
  - from: "partitioner"
    to: "fetcher"
    grouping:
      type: FIELDS
      args: ["key"]

  - from: "fetcher"
    to: "sitemap"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "sitemap"
    to: "jsoup"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "jsoup"
    to: "shunt"
    grouping:
      type: LOCAL_OR_SHUFFLE  

  - from: "shunt"
    to: "tika"
    grouping:
      type: LOCAL_OR_SHUFFLE            

  - from: "tika"
    to: "tika"
    grouping:
      type: LOCAL_OR_SHUFFLE 

  - from: "shunt"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE


  - from: "tika"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE


  - from: "fetcher"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "sitemap"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "jsoup"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "tika"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"
