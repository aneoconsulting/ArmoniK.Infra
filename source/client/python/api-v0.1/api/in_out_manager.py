# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 https://aws.amazon.com/apache-2-0/

import logging

from api.in_out_s3 import InOutS3
from api.in_out_redis import InOutRedis

"""
This function will create appropriate InOut Storage Object depending on the configuration string.
Valid Configurations <service type>

"grid_storage_service" : "S3"
"grid_storage_service" : "REDIS"
"grid_storage_service" : "S3+REDIS"


"""

logging.basicConfig(format="%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s  - %(lineno)d - %(message)s",
                    datefmt='%H:%M:%S', level=logging.INFO)
logging.info("Init AWS Grid Connector")


def in_out_manager(grid_storage_service, s3_bucket, redis_url, s3_region=None, s3_custom_resource=None, redis_custom_connection=None, redis_ca_cert=None, redis_keyfile=None, redis_certfile=None):
    """This function returns a connection to the data plane. This connection will be used for uploading and
       downloading the payload associated to the tasks

    Args:
        grid_storage_service(string): the type of storage deployed with the data plane
        s3_bucket(string): the name of the S3 bucket (valid only if an S3 bucket has been deployed with data plane)
        s3_region(string): the region where the s3 has been created
        redis_url(string): the URL of the redis cluster (valid only if redis has been deployed with data plane)
        s3_custom_resource(object): override the default connection to AWS S3 service (valid only if an S3 bucket has been deployed with data plane)
        redis_custom_connection(object): override the default connection to the redis cluster (valid only if redis has been deployed with data plane)
        redis_ca_cert(string): path to redis CA certificate
        redis_keyfile(string): path to redis key file
        redis_certfile(string): path to redis certificate

    Returns:
        object: a connection to the data plane
    """
    logging.info(" storage_type {} s3 bucket {} redis_url {}".format(grid_storage_service, s3_bucket, redis_url))
    if grid_storage_service == "S3":
        return InOutS3(namespace=s3_bucket, region=s3_region)

    elif grid_storage_service == "REDIS":
        return InOutRedis(
            namespace=s3_bucket,
            cache_url=redis_url,
            use_S3=False,
            s3_custom_resource=s3_custom_resource,
            redis_custom_connection=redis_custom_connection,
            redis_certfile=redis_certfile,
            redis_keyfile=redis_keyfile,
            redis_ca_cert=redis_ca_cert)

    elif grid_storage_service == "S3+REDIS":
        return InOutRedis(
            namespace=s3_bucket,
            cache_url=redis_url,
            use_S3=True,
            region=s3_region,
            s3_custom_resource=s3_custom_resource,
            redis_certfile=redis_certfile,
            redis_keyfile=redis_keyfile,
            redis_ca_cert=redis_ca_cert)

    else:
        raise Exception("InOutManager can not parse connection string: {}".format(
            grid_storage_service))
