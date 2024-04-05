import ballerina/http;
import ballerina/uuid;
import ballerinax/mongodb;

configurable string host = ?;
configurable string database = ?;
const string loteryCollection = "lottery";

final mongodb:Client mongoDb = check new ({
    connection: host
});

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9091) {

    private final mongodb:Database Db;

    function init() returns error? {
        self.Db = check mongoDb->getDatabase(database);
    }

    resource function get results/[string email]() returns Lottery|error {
        mongodb:Collection creditCol = check self.Db->getCollection(loteryCollection);
        stream<Lottery, error?> findResult = check creditCol->find({email});
        Lottery[] result = check from Lottery m in findResult
            select m;
        if result.length() == 0 {
            return error(string `Failed to get the bet with email ${email}`);
        }
        return result[0];
    }

    resource function post bet(LotteryUpdate bet) returns string|error {
        mongodb:Collection lotteryCol = check self.Db->getCollection(loteryCollection);

        boolean currentLottery = check getBet(self.Db, bet.email);
        if currentLottery {
            mongodb:UpdateResult updateResult = check lotteryCol->updateOne({email: bet.email}, {
                set: {
                    value: bet.value
                }
            });
            if updateResult.modifiedCount != 1 {
                return error(string `Failed to update the bet with email ${bet.email}`);
            }
        } else {
            string id = uuid:createType1AsString();
            Lottery cr = {
                id: id,
                value: bet.value,
                email: bet.email,
                last_draw_value: "",
                last_draw_bet_value: "",
                enabled: false,
                winner: false
            };
            check lotteryCol->insertOne(cr);
        }
        return "bet done";
    }
}

isolated function getBet(mongodb:Database Db, string email) returns boolean|error {
    mongodb:Collection creditCol = check Db->getCollection(loteryCollection);
    stream<Lottery, error?> findResult = check creditCol->find({email});
    Lottery[] result = check from Lottery m in findResult
        select m;
    if result.length() == 0 {
        return false;
    }
    return true;
}

public type LoteryInput record {|
    string value;
    string email;
    string last_draw_bet_value?;
    string last_draw_value?;
    boolean enabled?;
    boolean winner?;
|};

public type LotteryUpdate record {|
    string value;
    string email;
|};

public type Lottery record {|
    readonly string id;
    *LoteryInput;
|};
