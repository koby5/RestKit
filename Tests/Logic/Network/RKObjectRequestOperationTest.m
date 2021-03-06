//
//  RKObjectRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 10/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKErrorMessage.h"

// Models
#import "RKObjectLoaderTestResultModel.h"

@interface RKTestComplexUser : NSObject

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *firstname;
@property (nonatomic, retain) NSString *lastname;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;

@end

@implementation RKTestComplexUser
@end

@interface RKObjectRequestOperationTest : RKTestCase
@end

@implementation RKObjectRequestOperationTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (RKResponseDescriptor *)responseDescriptorForComplexUser
{
//    NSMutableDictionary *mappingDictionary = [NSMutableDictionary dictionary];
//    [mappingsDictionary setObject:userMapping forKey:@"data.STUser"];
//    return provider;
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"firstname" toKeyPath:@"firstname"]];

    return [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
}

- (RKResponseDescriptor *)errorResponseDescriptor
{
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"" toKeyPath:@"errorMessage"]];

    NSMutableIndexSet *errorCodes = [NSMutableIndexSet indexSet];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
    return [RKResponseDescriptor responseDescriptorWithMapping:errorMapping pathPattern:nil keyPath:@"errors" statusCodes:errorCodes];
}

- (void)testThatObjectRequestOperationResultsInRefreshedPropertiesAfterMapping
{

}

- (void)testCancellationOfObjectRequestOperationCancelsMapping
{

}

- (void)testShouldReturnSuccessWhenTheStatusCodeIs200AndTheResponseBodyOnlyContainsWhitespaceCharacters
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"userMapping" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:nil statusCodes:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1234/whitespace" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
}

#pragma mark - Complex JSON

- (void)testShouldLoadAComplexUserObjectWithTargetObject
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [request addValue:authString forHTTPHeaderField:@"Authorization"];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testShouldLoadAComplexUserObjectWithoutTargetObject
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect([requestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestComplexUser *user = [[requestOperation.mappingResult array] lastObject];
    expect(user.firstname).to.equal(@"Diego");
}

- (void)testShouldHandleTheErrorCaseAppropriately
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/errors.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self errorResponseDescriptor] ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"error1, error2");

    NSArray *objects = [[requestOperation.error userInfo] objectForKey:RKObjectMapperErrorObjectsKey];
    RKErrorMessage *error1 = [objects objectAtIndex:0];
    RKErrorMessage *error2 = [objects lastObject];

    expect(error1.errorMessage).to.equal(@"error1");
    expect(error2.errorMessage).to.equal(@"error2");
}

- (void)testShouldNotCrashWhenLoadingAnErrorResponseWithAnUnmappableMIMEType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/404" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self errorResponseDescriptor] ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.error).notTo.beNil();
}

- (void)testShouldLoadResultsNestedAtAKeyPath
{
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"ID"]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"ends_at" toKeyPath:@"endsAt"]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"photo_url" toKeyPath:@"photoURL"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping pathPattern:nil keyPath:@"results" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ArrayOfResults.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    NSArray *objects = [requestOperation.mappingResult array];
    expect(objects).to.haveCountOf(2);
    expect([objects[0] ID]).to.equal(226);
    expect([objects[0] photoURL]).to.equal(@"1308262872.jpg");
    expect([objects[1] ID]).to.equal(235);
    expect([objects[1] photoURL]).to.equal(@"1308634984.jpg");
}

- (void)testShouldAllowYouToPostAnObjectAndHandleAnEmpty204Response
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/204" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.HTTPRequestOperation.response.statusCode).to.equal(204);
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect([requestOperation.mappingResult array]).to.contain(user);
    expect(user.email).to.equal(@"blake@restkit.org");
}

- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContent
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(user.email).to.equal(@"changed");
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnother
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping addAttributeMappingsFromArray:@[@"ID"]];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:targetMapping pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    // Our original object should not have changed
    expect(user.email).to.equal(@"blake@restkit.org");

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[requestOperation.mappingResult array] lastObject];
    expect(newObject).to.beInstanceOf([RKObjectLoaderTestResultModel class]);
    expect(newObject.ID).to.equal(31337);
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnotherViaURLConfiguration
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping addAttributeMappingsFromArray:@[@"ID"]];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:targetMapping pathPattern:@"/notNestedUser" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    // Our original object should not have changed
    expect(user.email).to.equal(@"blake@restkit.org");

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[requestOperation.mappingResult array] lastObject];
    expect(newObject).to.beInstanceOf([RKObjectLoaderTestResultModel class]);
    expect(newObject.ID).to.equal(31337);
}

- (void)testMappingResponseWithExactMatchForResponseDescriptorPathPattern
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"/JSON/ComplexNestedUser.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testMappingResponseWithDynamicMatchForResponseDescriptorPathPattern
{

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:@"/JSON/:name\\.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testThatAResponseWithA2xxStatusCodeAnEmptyResponseBodyIsConsideredASuccessfulExecution
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1234" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testThatAResponseWithA2xxStatusCodeAnEmptyResponseBodyLoadsAMappingResultContainingTheTargetObject
{

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1234" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];

    expect([requestOperation.mappingResult array]).to.contain(user);
}

- (void)testShouldConsiderTheLoadOfEmptyObjectsWithoutAnyMappableAttributesAsSuccess
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"firstUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"secondUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/users/empty" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor1, responseDescriptor2 ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testThatAnEmptyArrayResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/array" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

- (void)testThatAnEmptyDictionaryResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/dictionary" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

// NOTE: This is for supporting Rails `render :nothing => true`
- (void)testThatAnEmptyStringResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/string" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

// NOTE: This is a bit of a curveball case. To support Rails returning an empty string, if there's a target object you get back a mapping result
- (void)testThatAnEmptyStringResponseBodyForAnObjectRequestOperationWithATargetObjectReturnsAMappingResultContainingTheObject
{
    NSObject *targetObject = [NSObject new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/string" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    requestOperation.targetObject = targetObject;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(requestOperation.error).to.beNil();
    expect([requestOperation.mappingResult array]).to.contain(targetObject);
}

#pragma mark - Block Tests

- (void)testInvocationOfSuccessBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/array" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];

    __block RKMappingResult *blockMappingResult = nil;
    [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        blockMappingResult = mappingResult;
    } failure:nil];

    dispatch_async(dispatch_get_current_queue(), ^{
        expect(blockMappingResult).notTo.beNil();
    });
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
}

- (void)testInvocationOfFailureBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/errors.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    NSOperationQueue *operationQueue = [NSOperationQueue new];

    __block NSError *blockError = nil;
    [requestOperation setCompletionBlockWithSuccess:nil failure:^(RKObjectRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    dispatch_async(dispatch_get_current_queue(), ^{
        expect(blockError).notTo.beNil();
    });
    [operationQueue addOperation:requestOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
}


#pragma mark - Will Map Data Block

- (void)testShouldAllowMutationOfTheParsedDataInWillMapData
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
        return @{ @"user": @{ @"email": @"blake@restkit.org" } };
    }];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    RKTestComplexUser *user = [requestOperation.mappingResult firstObject];
    expect(user).notTo.beNil();
    expect(user.email).to.equal(@"blake@restkit.org");
}

@end
