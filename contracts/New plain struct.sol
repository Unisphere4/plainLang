mapping (int => instructions[] = [Party, Token, And, Or, Greater, Less, Equal}

struct Agreement 
    {
        address originator;         // Party creating the agreement
        address counterparty;       // Party accepting agreement. Allow multiple counterparies in future.
        //address requiredParty;    // If this agreement is intended for only a specified counter-party, this is their address. Otherwise, 0x0

        int8[] logic;                // Where we store the contract logic. Must be a negative number. Eventually, all instructions and values will be included in a single array. Only "logic" is negative.
        uint[] amounts;             // Amounts used in agreement
        address[] tokens;           // ***token*** Token being transacted upon
        uint agreement_date;        // Will be set when the originator creates the agreement
        uint close_date;            // Date when the agreement may closed and either party may trigger closeAgreement 

        uint256[] prices;           // ***price_at_agreement***Price when agreement is created by originator
        uint256[] multipliers;      // ***multiplier***Multiplier against price difference. In this version, multiplier = amount_staked

        uint256 premium;            // Premium for agreement to cover losses - Denominated in PLAIN
        uint256 payment;
        uint256[] amountsStaked;    // ***amountStaked*** Number of tokens staked by counter_party
        bool closed;                // True if agreement has already been closed. Default=false, which is correct.
    }

    int8 private const START = -1;
    int8 private const END = -2;
    int8 private const PARTY = -3;
    int8 private const TOKEN = -4;
    int8 private const AND = -5;
    int8 private const OR = -6;
    int8 private const GREATER = -7;
    int8 private const LESS = -8;
    int8 private const EQUAL = -9;
    int8 private const PRICE = -10;
    int8 private const ;