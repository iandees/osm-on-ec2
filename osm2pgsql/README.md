# osm2pgsql

Scripts to get an [osm2pgsql](http://wiki.openstreetmap.org/wiki/Osm2pgsql) rendering database set up and updated on Amazon EC2 infrastructure.

## Initial import

The `initial_import.sh` script is meant meant to be run from the command line on a `hi1.4xlarge` instance. It uses the SSD present on the instance to make the initial load as quick as possible. Once the initial import is complete, the script will dump the PostgreSQL database data directory to S3 so that further updates can happen from it.

## Updates

The `update.sh` script is meant to be run from the command line of any instance type with more than 300GB of ephemeral storage available. It will grab the most recent data directory from S3, install and start PostgreSQL along with osm2pgsql and osmosis, then start catching up. Once complete, it will stop PostgreSQL again and push the updated data to S3.

