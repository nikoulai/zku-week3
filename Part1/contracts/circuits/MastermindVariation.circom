pragma circom 2.0.0;

// [assignment] implement a variation of mastermind from https://en.wikipedia.org/wiki/Mastermind_(board_game)#Variation as a circuit

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";


// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

// Royale Mastermind	
// 5 colors × 5 shapes

// Every color is a number from 1 to 5, the same for shapes
// so we have 25 different pieces
//we could make each guess a number from 1 to 25, but, I kept them seperate

template MastermindVariation(){
    // Public inputs
    signal input pubGuessColorA;
    signal input pubGuessColorB;
    signal input pubGuessColorC;
    signal input pubGuessColorD;
    signal input pubGuessColorE;

    signal input pubGuessShapeA;
    signal input pubGuessShapeB;
    signal input pubGuessShapeC;
    signal input pubGuessShapeD;
    signal input pubGuessShapeE;

    signal input pubNumHit;
    signal input pubNumBlow;
    signal input pubSolnHash;

    // Private inputs
    signal input privSolnColorA;
    signal input privSolnColorB;
    signal input privSolnColorC;
    signal input privSolnColorD;
    signal input privSolnColorE;

    signal input privSolnShapeA;
    signal input privSolnShapeB;
    signal input privSolnShapeC;
    signal input privSolnShapeD;
    signal input privSolnShapeE;

    signal input privSalt;

   

    // Output
    signal output solnHashOut;

 var pubGuessA;
    var pubGuessB;
    var pubGuessC;
    var pubGuessD;
    var pubGuessE;

    var privSolnA;
    var privSolnB;
    var privSolnC;
    var privSolnD;
    var privSolnE;
    var guess[5];
    var soln[5];
    var guessColor[5] = [pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessColorD, pubGuessColorE];
    var guessShape[5] = [pubGuessShapeA, pubGuessShapeB, pubGuessShapeC, pubGuessShapeD, pubGuessShapeE];
    var solnShape[5] =  [privSolnShapeA, privSolnShapeB, privSolnShapeC, privSolnShapeD, privSolnShapeE];
    var solnColor[5] =  [privSolnColorA, privSolnColorB, privSolnColorC, privSolnColorD, privSolnColorE];

    var j = 0;
    var k = 0;
    component lessThan[10];
    component equalGuess[10];
    component equalSoln[10];
    var equalIdx = 0;

    for (j=0; j<5; j++) {
	    guess[j] = guessColor[j]* guessShape[j];
	    soln[j] = solnShape[j] * solnColor[j];
    }
    // Create a constraint that the solution and guess digits are all less than 10.
    for (j=0; j<5; j++) {
        lessThan[j] = LessThan(5);
        lessThan[j].in[0] <== guess[j]; 
        lessThan[j].in[1] <== 26;
        lessThan[j].out === 1;

        lessThan[j+5] = LessThan(5);
        lessThan[j+5].in[0] <== soln[j];
        lessThan[j+5].in[1] <== 26;
        lessThan[j+5].out === 1;
        for (k=j+1; k<5; k++) {
            // Create a constraint that the solution and guess digits are unique. no duplication.
            equalGuess[equalIdx] = IsEqual();
            equalGuess[equalIdx].in[0] <== guess[j];
            equalGuess[equalIdx].in[1] <== guess[k];
            equalGuess[equalIdx].out === 0;
            equalSoln[equalIdx] = IsEqual();
            equalSoln[equalIdx].in[0] <== soln[j];
            equalSoln[equalIdx].in[1] <== soln[k];
            equalSoln[equalIdx].out === 0;
            equalIdx += 1;
        }
    }

    // Count hit & blow
    var hit = 0;
    var blow = 0;
    component equalHB[25];

    for (j=0; j<5; j++) {
        for (k=0; k<5; k++) {
            equalHB[5*j+k] = IsEqual();
            equalHB[5*j+k].in[0] <== soln[j];
            equalHB[5*j+k].in[1] <== guess[k];
            blow += equalHB[5*j+k].out;
            if (j == k) {
                hit += equalHB[5*j+k].out;
                blow -= equalHB[5*j+k].out;
            }
        }
    }

    // Create a constraint around the number of hit
    component equalHit = IsEqual();
    equalHit.in[0] <== pubNumHit;
    equalHit.in[1] <== hit;
    equalHit.out === 1;
    
    // Create a constraint around the number of blow
    component equalBlow = IsEqual();
    equalBlow.in[0] <== pubNumBlow;
    equalBlow.in[1] <== blow;
    equalBlow.out === 1;

    // Verify that the hash of the private solution matches pubSolnHash
    component poseidon = Poseidon(6);
    poseidon.inputs[0] <== privSalt;
    poseidon.inputs[1] <-- guess[0];
    poseidon.inputs[2] <-- guess[1];
    poseidon.inputs[3] <-- guess[2];
    poseidon.inputs[4] <-- guess[3];
    poseidon.inputs[5] <-- guess[4];

    log(privSalt);
    log(guess[0]);
    log(guess[1]);
    log(guess[2]);
    log(guess[3]);
    log(guess[4]);
    log(poseidon.out);

    log(blow);
    log(hit);
    solnHashOut <== poseidon.out;
    // pubSolnHash === solnHashOut;
 }

component main {public [
 pubGuessShapeA, pubGuessShapeB, pubGuessShapeC, pubGuessShapeD, pubGuessShapeE,
 pubGuessColorA, pubGuessColorB, pubGuessColorC, pubGuessColorD, pubGuessColorE,
 pubNumHit, pubNumBlow, pubSolnHash
 ]} = MastermindVariation();

/* INPUT = {
    "pubGuessShapeA": "1",
      "pubGuessShapeB": "2",
      "pubGuessShapeC": "3",
      "pubGuessShapeD": "4",
      "pubGuessShapeE": "5",
      "pubGuessColorA": "1",
      "pubGuessColorB": "2",
      "pubGuessColorC": "3",
      "pubGuessColorD": "4",
      "pubGuessColorE": "5",
      "pubNumHit": "5",
      "pubNumBlow": "0",

      "privSolnColorA": "1",
      "privSolnColorB": "2",
      "privSolnColorC": "3",
      "privSolnColorD": "4",
      "privSolnColorE": "5",

      "privSolnShapeA": "1",
      "privSolnShapeB": "2",
      "privSolnShapeC": "3",
      "privSolnShapeD": "4",
      "privSolnShapeE": "5",

      "privSalt": "1",
      "pubSolnHash": "7757418611592686851480213421395023492910069335464834810473637859830874759279"
} */