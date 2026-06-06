package org.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.S3Event;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CopyObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.time.LocalDateTime;


public class Handler implements RequestHandler<S3Event, String> {

    private final S3Client s3Client = S3Client.builder()
            .region(Region.US_EAST_1)
            .build();


    @Override
    public String handleRequest(S3Event request, Context context) {
        var logger = context.getLogger();

        try {

            logger.log("Event registred in "  + request.getRecords().getFirst().getS3().getBucket().getName());

            for (S3EventNotification.S3EventNotificationRecord record : request.getRecords()){

                var sourceBucket = record.getS3().getBucket().getName();
                var objectName = record.getS3().getObject().getUrlDecodedKey();

                var destionationBucketName = "destionation-bucket-gkowalski";
                var finalFileName = changeName(objectName);
                var destinationBucketPath = "lambda-worked/" + finalFileName;

                var fileNameChanged = changeSourceName(objectName);

                CopyObjectRequest copyObjectRequest = CopyObjectRequest.builder()
                        .sourceBucket(sourceBucket)
                        .sourceKey(objectName)
                        .destinationBucket(destionationBucketName)
                        .destinationKey(destinationBucketPath)
                        .build();

                s3Client.copyObject(copyObjectRequest);

                logger.log("Object upload in " + destionationBucketName + "named: " + finalFileName);
            }

            } catch (RuntimeException e) {
                throw new RuntimeException(e);
        }

            return "Process worked finished at " + LocalDateTime.now();
        }

        private String changeName(String sourceName){
            return sourceName + LocalDateTime.now();
        }

        private String changeSourceName(String sourceName){
            return sourceName + "sucess";
        }

}