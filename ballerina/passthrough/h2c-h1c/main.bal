import ballerina/http;
import ballerina/log;

final http:Client nettyEP = check new ("localhost:8688", httpVersion = http:HTTP_1_1);

listener http:Listener httpListener = new (9090);

service /passthrough on httpListener {

    isolated resource function post .(http:Request req) returns http:Response {
        do {
            return check nettyEP->forward("/service/EchoService", req);
        } on fail error e {
            log:printError("Error at h1_h1_passthrough", 'error = e);
            http:Response res = new;
            res.statusCode = 500;
            res.setPayload(e.message());
            return res;
        }
    }
}
