import ballerina/http;
import ballerina/log;

final http:Client nettyEP = check new ("localhost:8688",
    secureSocket = {
        cert: {
            path: "../../resources/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
);

listener http:Listener httpListener = new (9090,
    secureSocket = {
        key: {
            path: "../../resources/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

service /passthrough on httpListener {

    isolated resource function post .(http:Request req) returns http:Response {
        do {
            return check nettyEP->forward("/service/EchoService", req);
        } on fail error e {
            log:printError("Error at h2_h2_passthrough", 'error = e);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(e.message());
            return res;
        }
    }
}
