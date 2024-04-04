import ballerina/http;
import ballerina/uuid;
import ballerinax/mongodb;

configurable string host = ?;
configurable string database = ?;
const string creditCollection = "credits";
const string slotMachineRecordsCollection = "slot_machine_records";

final mongodb:Client mongoDb = check new ({
    connection: host
});

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    private final mongodb:Database Db;
    # A resource for generating greetings
    # + name - the input string name
    # + return - string name with hello message or error
    resource function get greeting(string name) returns string|error {
        // Send a response back to the caller.
        if name is "" {
            return error("name should not be empty!");
        }
        return "Hello, " + name;
    }
}


public type LoteryInput record {|
    string value;
    string last_draw_value;
    string email;
    boolean enabled;
    boolean winner;
|};

public type CreditUpdate record {|
    int deduction;
    string date;
|};

public type Lottery record {|
    readonly string id;
    *LoteryInput;
|};