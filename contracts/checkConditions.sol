const int8 AND = -1;
const int8 OR = -2;
const int8 LESS = -3;
const int8 GREATER = -4;
const int8 LESSEQUAL = -5;
const int8 GREATEREQUAL = -6;
const int8 EQUALS = -7;

const bool COUNTERPARTY = false;
const bool ORIGINATOR = true;

struct Performance
{
    address firstParty;
    address secondParty;
    address token;
    uint256 amount;
}

struct Token
{
	address tokenAddress;
	int256 initialPrice;
	int256 priceAtClose;
}

struct Proposition
{
	Token tokenA;
	Token tokenB;
	uint8 operator;
}

struct Agreement
{
	Token[] tokens;
	uint[] dates;
	uint8[] operators;
	address[] parties;
	uint64[] multipliers;
	uint256[] prices;
	uint256 premium;
	uint256[] payments;
	Performance[] performances;
}

struct Agreement 
    {
        address originator;         // Party creating the agreement
        address counterparty;       // Party accepting agreement
        address requiredParty;      // If this agreement is intended for only a specified counter-party, this is their address. Otherwise, 0x0

        address token;              // Token being transacted upon
        
        uint agreement_date;        // Will be set when the originator creates the agreement
        uint close_date;            // Date when the agreement is closed and either party may trigger closeAgreement 

        uint256 price_at_agreement;  // Price when agreement is created by originator
        uint256 multiplier;          // Multiplier against price difference. In this version, multiplier = amount_staked

        uint256 premium;            // Premium for agreement to cover losses - Denominated in PLAIN
        uint256 payment;
        uint256 amountStaked;      // Number of tokens staked by counter_party
        bool closed;                // True if agreement has already been closed. Default=false, which is correct.
    }

function getPrices(agreement_number)
	private
{

}

function checkConditions(agreement_number)
	private 
	view
{
	int8 i=0;
	bool result=true;
    int8 length = agreements[agreement_number].operators.length; // Use a pointer to the agreement?

    require (length <= 127, “Conditions can’t have more than 127 operators”);

	while (i < length)
	{
		result = condition (agreements[agreement_number].operators[i], agreements[agreement_number].tokens[i], agreements[agreement_number].tokens[i*2]);
		
		if ((andOr == AND)  && (result == false))
		{
			return false;
		}
		if ((andOr == OR) && (result == true))
		{
			return true;
		}

		i++;	
	}
	
	return result;
}
		
function condition (int8 operator, int256 tokenV, int256 tokenV2)
	private
	view
{
		bool result = true;
		if (operator[i] == LESS)
		{
			if (tokens[i] >= tokens[i*2])
			{
				result = false;
			}
			 
		}
		else if (operator[i] == GREATER)  
		{
			if (tokens[i] <= tokens[i*2])
			{
				result = false;
			}
		}
		else if (operator[i] == LESSEQUAL)  
		{
			if (tokens[i] > tokens[i*2])
			{
				result = false;
			}
		}
		else if (operator[i] == GREATEREQUAL)  
		{
			if (tokens[i] < tokens[i*2)
			{
				result = false;
			}
		}
		else if (operator[i] == EQUALS)  
		{
			if (tokens[i] != tokens[i*2])
			{	
				result = false;
			}
		}
		
	return result;
}

function perform (agreement_number)
    private
{
	// Iterate through each performance, executing each
    for (uint8 i = 0; i < agreements[agreement_number].performances.length; i++)
    {
        execute (agreements[agreement_number].performances[i].firstParty, agreements[agreement_number].performances[i].secondParty, agreements[agreement_number].performances[i].token, agreements[agreement_number].performances[i].amount);
    }
}

function execute (address _secondParty, address _token, uint256 _amount)
    private
{
    ERC20(_token).transfer(_secondParty, _amount);
}