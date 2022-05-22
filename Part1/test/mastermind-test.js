//[assignment] write your own unit test to show that your Mastermind variation circuit is working as expected

const chai = require("chai");
const path = require("path");

const wasm_tester = require("circom_tester").wasm;

const F1Field = require("ffjavascript").F1Field;
const Scalar = require("ffjavascript").Scalar;
exports.p = Scalar.fromString(
  "21888242871839275222246405745257275088548364400416034343698204186575808495617"
);
const Fr = new F1Field(exports.p);
const assert = chai.assert;
const buildPoseidon = require("circomlibjs").buildPoseidon;
const mulStringIntsToInt = (a, b) => parseInt(a) * parseInt(b);

describe("Grand Mastermind test", function () {
  this.timeout(100000000);
  let poseidon;
  let F;

  it("should pass, breaker has 5 hits", async () => {
    poseidon = await buildPoseidon();
    F = poseidon.F;
    const circuit = await wasm_tester(
      "contracts/circuits/MastermindVariation.circom"
    );
    await circuit.loadConstraints();

    const INPUT = {
      pubGuessShapeA: "1",
      pubGuessShapeB: "2",
      pubGuessShapeC: "3",
      pubGuessShapeD: "4",
      pubGuessShapeE: "5",
      pubGuessColorA: "1",
      pubGuessColorB: "2",
      pubGuessColorC: "3",
      pubGuessColorD: "4",
      pubGuessColorE: "5",
      pubNumHit: "5",
      pubNumBlow: "0",

      privSolnColorA: "1",
      privSolnColorB: "2",
      privSolnColorC: "3",
      privSolnColorD: "4",
      privSolnColorE: "5",

      privSolnShapeA: "1",
      privSolnShapeB: "2",
      privSolnShapeC: "3",
      privSolnShapeD: "4",
      privSolnShapeE: "5",

      privSalt: "1",
      pubSolnHash:
        "12432403805980842532745726429320144151364099056264896081065553025785029347107",
    };

    const res2 = poseidon([
      parseInt(INPUT.privSalt),
      mulStringIntsToInt(INPUT.privSolnColorA, INPUT.privSolnShapeA),
      mulStringIntsToInt(INPUT.privSolnColorB, INPUT.privSolnShapeB),
      mulStringIntsToInt(INPUT.privSolnColorC, INPUT.privSolnShapeC),
      mulStringIntsToInt(INPUT.privSolnColorD, INPUT.privSolnShapeD),
      mulStringIntsToInt(INPUT.privSolnColorE, INPUT.privSolnShapeE),
    ]);

    const pubSolnHashBigInt = F.toObject(res2);

    //     console.log("***", pubSolnHashBigInt);
    //     console.log("***", pubSolnHashBigInt.toString());
    INPUT["pubSolnHash"] = pubSolnHashBigInt.toString();

    const witness = await circuit.calculateWitness(INPUT, true);

    assert(Fr.eq(Fr.e(witness[1]), Fr.e(INPUT["pubSolnHash"])));
    assert(Fr.eq(Fr.e(witness[14]), Fr.e(INPUT["pubSolnHash"])));
    //     assert();
    //     assert(Fr.eq(Fr.e(witness[1]), Fr.e(1)));
    //     const witness = await circuit.calculateWitness(
    //         { in: Fr.toString(Fr.e("0xd807aa98")) },
    //         true
    //       );

    //       assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
    //       assert(Fr.eq(Fr.e(witness[1]), Fr.e("0xd807aa98")));

    //     assert(Fr.eq(Fr.e(witness[1]), Fr.e("333")));
    //     assert(Fr.eq(Fr.e(witness[0]), Fr.e(1)));
  });
});
