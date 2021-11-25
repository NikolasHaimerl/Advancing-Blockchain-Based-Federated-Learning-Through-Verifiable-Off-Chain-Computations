// This file is MIT Licensed.
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x00e289a8d93ad55916234c9649c3d1e13ab5ac80dee3416e6ea88ddfdcd43b0a), uint256(0x1029b2e9638381f6fe13ace0372f514199d2c609dd798ce74d94e9d59cd20c1d));
        vk.beta = Pairing.G2Point([uint256(0x085595bdfb8940e8dc813d8f6e89ea509368ae75196a89c1d3c53c961a98d9c8), uint256(0x0c93c8be4bb09c4ed53e32385cbe498ac1a38295681b992153a569a998c41669)], [uint256(0x2d32b29b40f70184ccaac5e475f770d62ee1ecbd53d761b4869a5acecde174e3), uint256(0x124a4b612a0a916d30d82afe57e851453eae0bf03ba585a333c11fb1240edef7)]);
        vk.gamma = Pairing.G2Point([uint256(0x036c84c0ff39498e2348204ede1862fc0a2f011ed0f12bdfbc90c7f583380dca), uint256(0x0de04c6b6bd8c9a4b5b607e678727b9039f68a3fa6fd30942a5519ea8c126a39)], [uint256(0x040628f16f6e69ae1df7fd8d0f4988870c954b47a12a1ee52c036323fb3caefc), uint256(0x07c3f6780ee6f4a2e83e62743641b6504166f6b528359b3845351fe055609d92)]);
        vk.delta = Pairing.G2Point([uint256(0x07af6d1aeac24feb1365159c89d6d5e0680124f98fa434f5408081bbee1958b1), uint256(0x24241df12a61f396bdb218f609b7680c183e250db9e273c1d7c86bb4f2316691)], [uint256(0x26ff0632b04546fd0e2081b28238a443a30faa724f9300fba7448d2da052ec7b), uint256(0x0194188849b44a70f5d657993c8040df49ed77ea3df554219d7228199cf144e7)]);
        vk.gamma_abc = new Pairing.G1Point[](184);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x019eded74876df5da9b748ea43d2ca7f06a13f7ad86a81f1d27215012b43e140), uint256(0x171c91a4305dbdb5afab9fc55f2fe0979def423e2b8e26ff7ee32c497b35c310));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2effa80af9ac71b5deceffac9ee4c9697754e1563a6881d7eb7f48531c05a06f), uint256(0x160b87edb598eecb3822ecec353f695c591c7ff0203300e435d7401c1ce86eb2));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0f8afbd4b74db23374acf80b1caa5833621c150d52bf5aa21daba5d84f52764b), uint256(0x2c86d87b20357193c5483e09edccc71ebcac3d72406cf6b3dc418ed6e136e3d6));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1978aad3d248cc0c6db32ed4f3e510d86402a3330c15192fb6577ed54375f29a), uint256(0x1522ad90d070d112adce067cb3b4fa1477986e95bbb29d3e8ab3c219f9faecb5));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x01d0e69541b3ddbaa148404faf8b9372d060127ad34aa07a491a242cc2864a0f), uint256(0x2d4e419f73ebe1a2417fdd5e303d5208964b5445d2e2598d1846374df51badbe));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x26a77d762c975ecd81545796d843fa705cef7bc890b1df1199b772fe8d64ad0e), uint256(0x0afbf7428a5e7c3868b056ac861916ddbc3ecb0856fb133e19ae545d7cf2de6d));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x05b6c271f652f0ee8e33fee647eafc410ed9ac0cf5255ebfd1c156107027865f), uint256(0x1c05e3f6408f6c2a46a7f2312e3be510f969cff172448247a5564ad8a60cb749));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x07d2153be17bedbc8043451f1c70007f7825c15ed8306d20b78c608f66697e91), uint256(0x1761352d211cd05e03e91bd18db42e93c68b3a8297ade22731166fa21fd37df6));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x19a6d321d088206b7dfa5e827afe706f4f5ee8e71b3b84302249e3e9f85c6c91), uint256(0x279db8e4ed8cdfc8ff901ef931792c3ef13268ccf12c2d90cf0bad6453a6a484));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x12e430d905c47d3ef3c5d102cf686ff863ef1249fd691ff27b03b77585bcd9ce), uint256(0x025bc31486a0268ae534a6fd442cb9d5a2c16215c86cb39c72d743d2355d651a));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0f613abe95891a3bca315e6a29c0b3eba1ed8c0fbd6346233b80e04415b31912), uint256(0x01d3412d637765dcfdcc5e633eaf89d6404239360858b243f421e4628a63406f));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x1bb233ba3b083654bcc654de04f79bff892a18fa95627d5974d7fec15ca52f37), uint256(0x29d1190cf34c3e7d0207d7b6876067df2ac572df1f808b6f069695507f3c41e6));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x1c1521fc326eaa1a4a375036704459e51608617c56240a958e56deea1148feab), uint256(0x1a6f625477d1ed99a52ffbf33e3c4518701a9b792d4eddc384e0b422aaff6a88));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x04f2ad2e40dc2b608769ffa5e75e03a30ddfe9221dbba8c2ed3c6420e46e8b44), uint256(0x2287e0b7014b63b0119da083f4290d1d78364509db40aa7e21361df3646ce806));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x0fa46f813cc90d4f01035807361827a051e1f94e23fa86dce0caf7c4ab1c2495), uint256(0x1089957b1df8fabd38b7f9fb01dca70b24eb671801fdbb48702c1d7367d425a5));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x2f05007084b89c20a994712dc05e67a180ab00a16032381a565aeccdff98c1c8), uint256(0x11e24de8f3c747e084e19e0d94dd304328241b7564a73e96774c71ca4560559a));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x28edbce39e7c9009a198c4b00465c6db5fb47e92548e81fcea3bc718c295ebf8), uint256(0x136ee5f64b558baa064be54952cffa6de0623a2035e1500c6bc0f1cb9feaf622));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x21e17c56357152143768f351c32691dddd6c999dcb5640abe128d2b7a4606c0c), uint256(0x18c99345196310707da92162b25c5e860271a01956d15d7ace3f72338e1668b7));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x2daf66f86ff6407efa6c4f8dfe29559f6acae379ef62552723e98f46f2b68daf), uint256(0x04d226d788aa85aac58c344a37bd834fd40bd6deebf4dc5c79718752b6713c31));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1d145acbc30305152cc165c9343522f284eeea6460c6407c78f1515ef46782ad), uint256(0x1628e6577bbec6cb73a742fb29d7ed8ccd91232df996068025a22b291a7760c3));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x12867cabc970308a6448a3c64306a015e695a1a22ff11c8a77e338eb3a189ba0), uint256(0x29653b7727eb753b56b949373364f6355c0a1d19c8a8ac5bee2a2fe143033a95));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x250e2f36d90cc2d7dc08386a47dc4b193137e22ae35af532403d6bf04c4b34ff), uint256(0x1b2090224cca83b97ebf4311ecc4547096d0d098e5b3410c1db6174c8ad35313));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x292d9f183ffa7a7c1825c3813f5643c41d7dc96126e1b2a0e47678e36b9ffccf), uint256(0x1739ce60328001ef8d1afd24e473de0ea30ed4f8a19e5532a0e8fbdbdcb750bd));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x0e3708632acd8be1c5d39141d4f6741ced8262cacc6bf596b0880e6e1dfe2e65), uint256(0x258d9674527130c46dc68e72f05fd28df778c384a7facc1d94999970f0bb369a));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x1b9e41da252d33623034411451dc0ff56157176be34d8ade936c2b52c7e2afc0), uint256(0x1c2f0bddff8048ea2547fa3cd22bd039d1b9f596adc53e71531f77948a7b7434));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x2647afe282ff51c8d0aee6a2ccb9fbe0144a18b209579a99231b4225b3df87cd), uint256(0x0b21d869be9975ffa6e3101980f06c28f9ff9419395b26dddd97a3ee0eeedca6));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x0c746e5c7b7520b655b5af4693caf9d0eb173e5c4ebe67183b0a474a94acd6b5), uint256(0x304b29e5fce5c73da1cb29a67182e3dc33a943f2265cc092f282e0084afcaf35));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x2ee7b17fe1189a689a7a278a802f854e3d210aade0caf5f45b29a927fec02f3b), uint256(0x24ae8619cd4d5d136a38a7168062584fc2b5cc857be3b9ee6065dac10ac94688));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x2b7e610a23795c8c068f854238a3a6e2f372974441056560d7f58a623f337c42), uint256(0x0e9886be586f5feb885102c1e524c061519d7f861e3ece286e643576533f88ce));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x0eebba49b4e161d9286c78ba5bb723803575148a2320b84f9f757c60a6bd06e5), uint256(0x16e38a692904541fb76e6483efdb838d4afd7e4855f30489bb822a1cee34a15f));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x1d5ff1f4b08288bc080f5aaffba6e46d68ec6077d2379c357e8f439a3f122754), uint256(0x1514d5a341101c76fae50eed380a17a0bb9f5205e23663da74288d2579024066));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x221615bcaeefed4683602f9cacb0f75cbf5d5c36b02bba27ea5496ad64026a96), uint256(0x181f8c49979e387f74721faa5fad9055d8fe03892ec2669c512729cd9b7cd6c1));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x24d97c142df1e61ad87429ff881293af15d59704c0757f4cc23c9d09f771ea92), uint256(0x1f91b9eb4552ea3a2980506bb343d4f898fcc33b82f443b72be24059a32d47fa));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x164636d23157e6defe076cc647ce00c0a62209eaab3e061f6bec179e5836eeed), uint256(0x024671e33b6a313e1519e0e06196f3d9460b44553303b31e2a2bbbbb2433466b));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0ca18087fb95442a187b46f5073b50e41b6fa831e31e95ba5f157a75bf4e5b4d), uint256(0x183234bf48e3faa735126a4ec8a6d54a311b490e59b2ad3107ab5006c3d2afcc));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x1b17c48f7a37c229ba48e7444fe6d6b538f2e376b7a7abb04077f10c16021007), uint256(0x1a05ecdaf45bea8acc833b4f5bb302d86f8cd5622e29d92933a8e437c0e1af65));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x1b74f0d8aac8a94f5b3d0e0b2d654a86837c053d5d462dcd8a64bd19074c360f), uint256(0x26751f95a0ec678479b7adc87bbef6f5bffd185534d2d0c9e9791f5acf532542));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x1dfc2552e4cae7f482bc58f980cbfb9ee655f79e90bbcbf8ec1251c2414e6df0), uint256(0x1b4f8bde768ff77e1fa4de1f9879c00bfbc6cf63c61539b310ed4446b54cde61));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x0265207aeb997d0930009912cff2b7d63732c396336b49bdb1d97167d134f4e0), uint256(0x013c3d82c50ec0441e6039dd90e7b032bcafd31ddbbbcbda3cee69fe576edc44));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x240c13cc46d2262d395458d5a195092b844bdc06f94ce2d5bf564933badf965c), uint256(0x06c85711124595110843e5efb84eefceafeb2a4e7b25ac89e4de64b1ca2fa8ad));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x265e9147d11e172582fd92f4861e2ec620f32e7810b7779f1867c4ac6423972e), uint256(0x12c38feae38d65faaab341ec4cda43145292c808d44fccfa0c85769471ea18c8));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x0e7f54e7b406594e432d653d308d7a63138301f517bef7fc21f10c4acf291f1a), uint256(0x1f0e9322c39e1b22dbfcc4433416c2c92fe153eac802dee82aad5a0e1f056468));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x2f3a1fbfb8f3e650398223473065816917efd20a89778f4babf4a23be5b44f49), uint256(0x1c53bfe31718d36f71c7ed4bafde1bca152fcbfec20fecaa6c4f238a769acb11));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x24b5968a84e2d0c2d25d4941c0cdfd4624b9dcf23e37ec9e01a0d2be02d76e3f), uint256(0x0c62e1e375393b2cb5c0e3becd9cac74e8dcf562d264a13335fa7131d7046029));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x13c28138059e29224b791f892915d2cee8d98183857b3b0527e20d8ffb42bc27), uint256(0x1138dd9da94744bf7c3d2665032924e19f23bf9a9b785551ca38f73f68cbf0d5));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x1a8e57f8e32c411c9ac8d87fac31169288a6a9c488e840e0bc28b18e598b3f8c), uint256(0x1380d3e3aab72c54ca58a6d333d52158a9780f5175c5817c7768c4e1e96abe6b));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x2ec2d04877623aea2b6e113b40a4af121e817f1d4b8da494282498b4fe66a9ff), uint256(0x27fda8c917550db3c8198a6963222c8d334f74186ce2fbd7a8f3177c2a8db4c4));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x26a0c6f4d9accd7f1fe1c5057d3cea114db0032c0efe4165a2daaa5b68013968), uint256(0x12592d70e0469aae0683d89599346233f0b0bc513298e3123841a42783648a3e));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x2ec6f81bb5d786870b095798ff106a47366b1989a09793562a253c30953ba68a), uint256(0x0d30453702ae752d7ec5fd79c9c593fa57b1af67daaefe7943e6015bc2335946));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x289c189ba2deb02eabe9647d516649c99499a1f1fc69bba2ba09ae901bfef318), uint256(0x07e8d38344b0b0023b08bd1139f76e811b80bfc61827cbe27fdb6746ed4ab595));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2176e9677a22acffbd57e3c3d8f147b4e99a4a289d4c327754bebb8e85aee778), uint256(0x19d9fabecc85ce7b18e49fef0f26f49342df1079ff801abd2bd4a451dad48d71));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x226b8a10ca981f15f91967c5c170f64dabf00c5d544307ea5ad90cdb4e2eafd5), uint256(0x2fe346baba6b07fdd2418c387bb04ee8f46ac4bb9c9eb38ca2445252428d03e8));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x2d85967c0be37cd763aac17ceea9fd9fd7360eeb2c52858ba76a3b3f49fc89ed), uint256(0x2238464b2bf3931c94d642ad54befd7a44b7ebdc7d6f00e1929a0cfe8b82a24e));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x04eba721b1e3cb620b3f4ebfb88693da7cf3fad1f944f42d714ebaef5863feea), uint256(0x01d2501d65fc9733852d87aa80b638d21873ea3d17155b936439e4220252efcd));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x005ee069794ff9f38842f83a360bcc21cfd62811e6441503453b44b228f30bbb), uint256(0x1111b440c504df08c0649fc0582b3b4dcfb6e1fbead38b874067ed7cec80e8c1));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x269455ebcd458a5c7613452fbb8f3c6f3a0b536f9d26e0f71b3862ffce6a2a5e), uint256(0x23ea53b12f6f916bae2188c60492fecd62a711b2d3aba36ac80e5e417cb3dca9));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x27a63f3c05634c4bb3aad42cd5164eb627f4343dadbfee6b5bc6da7a9de8899e), uint256(0x1adedc0f0e340ef6386b9bf71c7ce60280a8593b86c24c1e8c2196ee634b383f));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x20131174189a2737d18ab16d3d0c0cae0822f6af31d6f9ed91e613f7e7203dcd), uint256(0x17eb7550d7907ead1a58f7a5c35ea5e1aca72a4c38f66568e31b98c9013da1ef));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x112b2c06166d1f5a16e744ac0861eb0c1e627fc6b0778baf5fd645fd68544ce3), uint256(0x03ab41b99885f0e4f26fbd753b0f573420e1dcb18490ff9e2f2d70f667ecc21a));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x2511ce8610ce921583bdf93b92b551f5d3e6c0612a3748bdd32f092557cf7c81), uint256(0x0d94b0062da1fbd7877a6f00ea9e74b4342612c6750902de605ba3e08aff633a));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x140df2af8eeb478df35d039e91bb7f633df7a40711e91a9e002faed71fda89a1), uint256(0x20ec70d39880ed4bdd77dec23e3981b7300377a48b9d4b438198a30d7ce24023));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x19113eed48ef8cf79d9899adb91cae40a98a151999779058f16f930823fde402), uint256(0x0d6ee3cd334f0155b299d97f01325a3bd1bc65f467c0de1b7decba1687eb8060));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x1675420c35104c29a22b8db8bfbb5bcb099e3ece415110091dc3f40e38d11f56), uint256(0x244ffcc3857e92fb57b2b9230e6df673c14daeb3b665a7208840f5b96ca25a56));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x1274f560b9e09feacbf53d5c70a1419136bef06f6d69ab7cc34bc0fba1e412e1), uint256(0x1e3d73bddab53a72d6da57922ab75d66ece469858fd89ba901a19e09a1acfce5));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x23eeba844e58b1c3a4aab8dc6f6ff81b3187bacdd09d290560cdcacddb2865ac), uint256(0x06f31ab6152ec170757e32f33247170b6076db451914831da5fd5d725e964544));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x283842150ac7bd2c47645bd6eb8c64fc2838805b6285d92cc674b550d6f6298c), uint256(0x0d74a40be9ef5f0fa8045abf6920158625e1ee55a7e334d9f1130a4490f094dc));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x2002b1a1c9a66c20fe41bacc9aba2e48774dfc25e41baefba02fa26b208e84ad), uint256(0x08b89d1e8a98c56a414d248f7471b69e3754874763d2232ad7b7cb0af15ebc56));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x1f55b7f34731dc73ce7fb141dfc260f14f0872feb481ce3b2707b5bf0fff3df2), uint256(0x1f737f5926a63e29deb947e697886105053ddb49f50ffa06c2db04e1aecf3a45));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x1da139955b926bbbf8b73e7cb104a0fe884405f888e29eebdee21d25ac9da8d4), uint256(0x2dccb4cef551262e267d57b2202069b97edbd421083bd20a39faa4ff4d75840c));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x0539730cae58985768e1ce7e46459ab171bfe15095b40c84799592bb750d09e8), uint256(0x2fd4c4d8c517f53b9829b180559f87c9b61dafa326867306d195423645680ea8));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x256a50baed84da26c0211dcf07fd0d8d24fe307516eff55989262c7f8619caaf), uint256(0x201cea7964ea9c36ff65515b2792ec0e73dc84bc36aa545ed301ddabe6ac61c1));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x1913195cfb1630a64eedf97a4b7ca4e80e69a0e973d6c11a0f3295fd6b15e0f8), uint256(0x272aff501baffc08c8df8d0aa4d337b60226778dd5ffbe3e952dffe00817543a));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x2e5fe7dd9e253a9682ad39ebeb4e035f9b9d8c596ba428a558cca5272022cdf8), uint256(0x1abfef0e87184250ec5140019701fbba9041c04a210cfd023928d7026241e99a));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x2916d6c3bb47c5ff33f7c531a9a8fd0acbfb1a06e8185f46a7f79145bcfa6ffd), uint256(0x11d78a076ca4fecca981b0d2f79954fd89125b8b99cb9ec2c759307ef83b4957));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x2f2f4f3479b57cc88eceda2b29379611792430a9964d0b88a52b462c6cae29ac), uint256(0x276d635bcd9095154c778c1b6b047e43eb35cdbb38c99c19df865000b15da3eb));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x017f096b688fc2b7fd7c81f03922fb72205d63043dffb079744164199f7873ab), uint256(0x0f7b8db27cdcdaa68b79ae5c2144aa366a8b6452107531da7d2bc05a3d21e244));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x1f4966f5a3f2277a843416f36dbedbc040332990e179d32f2f9abd9ecf406fd5), uint256(0x17e1bb635727ec918bf91acc5f2acbaaf2c9ad82e1cb2fca9e691ab4f956a6e2));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x1ebaa9b1a20a8eee7b60344b0b2db1164bf8450d4f078cb4be6704b1172a8369), uint256(0x004b679d5eb9f79987acae507c49cd97da43f50b410e5ef9b9d5430cea4863cd));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x29f649b75eab41c08b92b90b5bfccab1ba7c928420f6ff537c55da5ec7c83682), uint256(0x0ce91e678e94b8f849bbae924f2284c2f982cd84e9bc333da938f7d48f33129b));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x0130dbde581d7a42f543e0fa2acb7979ae4701aadb63b2adcca78ebbdea57370), uint256(0x13b538fc1040caf13415d15f078472951a50d84d44ed3c51a6dfb8c1db84beda));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x106182a5969ec1ee111373fda9626ae6ebcbed9ce0825d2a90a21c1157ca44cc), uint256(0x18271755eca415f4d43116cf144bd73053506f573d8014a9f9b2a5ab15560521));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x221c3646de764fe5dab74cf0ea53ef0ff285b041eceadbf494ae21c835046df3), uint256(0x034a9b814aa009e863c3e19866f1f23fd916b8af609b1f855e430d8021e55902));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x242547a39cf589a70dba150dcd51777d93e434ef72d50611c9991123ebdfd506), uint256(0x1a1825009be2b78f348e87f95bb99e2d088e50037d27ebd537dafb1a395dd9be));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x01b791937572effbd252231118d858a66511fb80eee2bf7356110524a5bc06e7), uint256(0x21d5a9c492226d7c26669cb3d344386edb17581ac6d97c07d1724a9ac4ae3715));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x1fd6d803b3978e8aedb846cf19e1e957d5e3f43f0ebb13ee6728fbd503b137bf), uint256(0x21c250610e13970923e1e31ee7daa79ae4ebf0ebdfb0b703a6231c960cd2d904));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x064724d779f031e4c9cfd2df872f8f654c355943a724e795e59470f9771de7fe), uint256(0x094140cb5702fedf90b6d635a42be01f5aaf7b5dbae4f047aa787ad5d51fb35d));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x155ea6bb29558145981e9578a4834b482d6aff427c4c3a7da34f91f2ffc3a60a), uint256(0x16d23c6c70dd75bd54b9d7ebe0c962ec334fb7949cea9f708b18c5c6b28baea1));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x2dace147a79df7eb3fd4e9d6e5cd40bd8bc1a9d847505de3ce51e795f7244b73), uint256(0x10d592b41e32933484ab45d81d96b66908bfcc252af967ea7e379c44ad137a7a));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x0afc6e9513b7f4da00a814f9e892866ec4d582211a45890f28d99debe14dfbef), uint256(0x23d4da4a9c4befb476e5b728780080acc279dcc8bc16b445694dbf319e8f1afc));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x3054cc036855a52fc8208464b48f60619f6084d78145abf404eec327333650a1), uint256(0x2930df7a1e7c9970f974b7a64f797b63b3688a3d28c4e34b069ab5313beb259e));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x11e201ab02e72eb86ce11db20f553cf41ea8838211b87471d2eae19df3894e9f), uint256(0x112eddd7a1662df7e2556736302b399845fdc3b1abf93403eab0f66b447def9e));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x15ad85b87d1caacd06d264f2a608bcbf70f4e625b9e660781b1ca4b636575a9c), uint256(0x153c7bd50ad5bd32a3fe9094b5f02b4b41767848cbc3e389a24586bc1b8aded6));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x1c39d45021819cada349aeea1b57561feaffa424eabcabe06ea8bcae44c5f2d5), uint256(0x0e5993ccd41e7304e018dbd5ca6969ce7913dc813b5e5cbc9e51192fafcca7e8));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x2b11e5b9d0f9db1c50f0c18d8d763116606f6a0a616221ab19e3dc0a0476de6a), uint256(0x01547981df071b7bfef1b7d6fa7441c1f98ef9e26e24ce2c810ed6150b1273fb));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x2df58e917b2dfd559d0351aeab7f3105e29d8a281a157eb6da52783b04012bfb), uint256(0x010ece00a0a1f5a8d63b61045539bd0de7ef47299ad70d487d170e02d477b635));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x0b25d5388c314202056a1ad17737651bc1a7da591959f5511304adc159385016), uint256(0x01aaf5543101da3663fb3580c7cf11014a3943c4246d277f23e0fa71b229938f));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x0e172336fa7fc8e5e9611a7f4a246a426ef92515ac9a0d63231e6eafe6116d0e), uint256(0x2228afb9c6c0f2b18ce5300f197546f66a9f9c5ce9ef4e99ae0e4d8ba20c90c8));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x153832120c646a2ee16284671b1c283a82230969a366df1b0e42c6cec3dc27ab), uint256(0x1dc38403aa27ab6c02371a4f060e7ef10396823bf3592e75f06ce276301070f6));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x09e56e8a4901d28731d50b100a8ead5b5a24c74cb68320c1639bf42d3df57aa3), uint256(0x23d5b3f43f0a4aa9b25724ac1dd84c564a98bf5a7c9fe8ad88241bcc64c92043));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x055bb95dca25191af018c5dd5e9a711f6d16484fe8fb074aa478aecf5f3a2681), uint256(0x1cea7ea0ac8a0b65a23bdd34b3b242cf07d4b17122eaaf77a5777b363cbcd955));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x027678ef2f2fb1a88808f94422818a45e93d0c06c51a998dc39ee3f21f11c60c), uint256(0x2712a28e53ed4b02faecdd53a9e73e67bf49d5ef5b62e0fcd340b0a2e92ca7d5));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x0df6e9f72b72f733ab9ad89e4464275f4efdbd012c26dd4ad57ede09926e4bfa), uint256(0x24d5e8910ce6cefbc9afd2a419b25a311574c92acaaed4a58a90b6315465debb));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x2b29632711d29e0001abf973e3201ec285af16ebebad1eff3e2fdef2fe5d09fd), uint256(0x2aa222d91b9810ad9a52afbde9b93bbf5343b219da8b5fc2bbe125bc773927bc));
        vk.gamma_abc[103] = Pairing.G1Point(uint256(0x28a7321f96ec295cd673781f015870ca768056a83a9b8793fe680b7ac5a73e68), uint256(0x0c3a98496ce7812e70eb1c2d254dd90c7778d9ba47c9cc737d65737a48d67802));
        vk.gamma_abc[104] = Pairing.G1Point(uint256(0x0b4f6828524040a46bb23a0b6b7e9ebe563202d8aa1c9c8d2ff7f554878d2294), uint256(0x2768c43d13c5a36ec946998dbd74bbf36709a7fa64e7ff90035774913e59c79f));
        vk.gamma_abc[105] = Pairing.G1Point(uint256(0x1b383cc926d0421e6681d7f531ee98a5473fc17008bbed9ff5053ae545da7315), uint256(0x19003768b941fd4e4885b2afb1a251337877abcc504d61b4b3553d535bda6bf0));
        vk.gamma_abc[106] = Pairing.G1Point(uint256(0x058eeb1a9088e678594931bbd898b2d84de3bfd5a33a6efc0256f2be2bb4a58a), uint256(0x19c1060b4215b7c75d12af6a6ca1e14b1ed99f938a594a21c86188fab1de733a));
        vk.gamma_abc[107] = Pairing.G1Point(uint256(0x2b56493e6bfd8abc7500ba552426b00ee9fb33317d55377201066c558dd7e694), uint256(0x24808b31a15e49444368c055510362dcd0fc4a4f58d64649aa36ed18ab5e7919));
        vk.gamma_abc[108] = Pairing.G1Point(uint256(0x05427224ee056aae2b178b839cbe24c7d86d47f2e75d271d04db0d0614e2ab56), uint256(0x12fe8e99d8426f68a1e4550f9309e6722d290b49b46da8e58db9c313bba113e8));
        vk.gamma_abc[109] = Pairing.G1Point(uint256(0x174b7955481d86710c14222517b84be55b3084df8469b84701b492500e658a16), uint256(0x2591b9292fb1a578bef3f0cdb7c442e1b8e6aa464557ecca004342f821845715));
        vk.gamma_abc[110] = Pairing.G1Point(uint256(0x2ffd42c5bd324b95e0d8d2cdd018c530d94f0698246d56b3d4844e51fc29fe08), uint256(0x0c13e36e7b34f75f1935c768a91b0d5c846d6a929cb4e45115651b90449fbfbd));
        vk.gamma_abc[111] = Pairing.G1Point(uint256(0x0f510fe5f24bd8804676ce8443361621ddd65eae34b4b2dcd2d48ac67f760f7a), uint256(0x0ee56ef321f0394f4d78bc8ae580a1bd057a35d263c80323b367aa8a0b5dbd60));
        vk.gamma_abc[112] = Pairing.G1Point(uint256(0x06556fc2e0289ffbf9153a633fc6689669c4a3efcb18ab8f48f2a8c90d0bca91), uint256(0x2867aeeb671297c71791be59d7fec26943fddd94b9925a22e6434fc3d20c6ee4));
        vk.gamma_abc[113] = Pairing.G1Point(uint256(0x07042985c7bee476ddeeb2729530e4d989cbcba2ffb69b1747d5a5f291a7d7a0), uint256(0x0e65b9e027f16f5a5f598bd3e1435ab4e0459015efc390c83a4e9516588001ae));
        vk.gamma_abc[114] = Pairing.G1Point(uint256(0x1ae48338fc0cfb0d2ecfe536c28fd6025b4dd1438c3e9d21c2f772581776ad8e), uint256(0x1ed12a90232a07038a68d8ecdbb72f490dc85154559a3362b52dedffa7d7a8ce));
        vk.gamma_abc[115] = Pairing.G1Point(uint256(0x1df23000d8d97146bfa4bf30c1eb822b08cde77c5c634036cf51f3fc09ac640d), uint256(0x13c558d8fe655f6ea2d027e8ee488998dfb9d0a0bc1a389e6dde7639982c29ae));
        vk.gamma_abc[116] = Pairing.G1Point(uint256(0x00584ac8af20dd664db2cf2dc9c73cc8b618d8f77ccc0bf8a609f762c6c35f1a), uint256(0x05f99f4323136d23ab9493b339af79df08f73743a9abb7cdb7965fc744d660aa));
        vk.gamma_abc[117] = Pairing.G1Point(uint256(0x0503d440eb7e58b7bf91fed98a0a54fed31420c01664d8cd17fed789ba258133), uint256(0x0a6ce01e1e137101fa29725fd070ab97bb03ad3622b483bc733f14a5bbd2a79a));
        vk.gamma_abc[118] = Pairing.G1Point(uint256(0x137f50b160ed064634adb44b778a3a839a22caecd43162cee537ffe3d2ba5014), uint256(0x14ac19cc67ad2f1e396e6b12e25d02a42c073bb87b95f91b146aec2cf9a2f2e1));
        vk.gamma_abc[119] = Pairing.G1Point(uint256(0x2b1e9e0444e70911c481ba33d658914698036cbb15c790d754765e5192209e56), uint256(0x211e59419ec63001f5a5aa2ab61c4f3160d6e144bddbe097396f862e9b79e926));
        vk.gamma_abc[120] = Pairing.G1Point(uint256(0x0b12116cead0e417126c34748924d3bf99ebe746100fec4c7d181924f847ac8b), uint256(0x221dd2a622eccf25e309d6385d81069fd2092175252e19a13c263d6ae2e57b3d));
        vk.gamma_abc[121] = Pairing.G1Point(uint256(0x2bcb27f0aa92d2a889b5c6e2cb70315f9c8a2317efe6a22613674a25a8cdc2ba), uint256(0x1a4e7b9b73c5576bff40873a69b6bc93403df36644c8f180cfb02c181f316e65));
        vk.gamma_abc[122] = Pairing.G1Point(uint256(0x0691c0304f808de6f7e0bb34a17daebc47089f44ef9e72824c5f1acf76ea7945), uint256(0x0a9beef996c21f09e7cad428326b372c76d12bd05f9155bff77072195b840679));
        vk.gamma_abc[123] = Pairing.G1Point(uint256(0x1f2405e6c9d72cc8ea96c6914d6511b9a176a55c5df7e55ce5e17a3bde075df6), uint256(0x141ae4da961c39fe9c78c410cd26609dfa7747f05dd6f260deaadf1a90efca36));
        vk.gamma_abc[124] = Pairing.G1Point(uint256(0x2c29d459ecc03875f8452c402fe9253b693f9897e07688fe3d2931759372f54b), uint256(0x0bd5862be925faeab0a7031e3426bc59de07a556636d871ec22cc3b7fc1c38c4));
        vk.gamma_abc[125] = Pairing.G1Point(uint256(0x0f4fc1d0c45f52114b5a89054dfda6253d577cede6bd3f25513608b190ae4032), uint256(0x20c946fcbec73b7c6415c6898a119e7a1ceb5562abc4e15c9308e63fb081d123));
        vk.gamma_abc[126] = Pairing.G1Point(uint256(0x1745d0ce498a5f8df24a7a58173553d7c6588242c821962e8b60d20f75bb6faf), uint256(0x1e5750fbebfa53f51dda55655f899b4720e6b1dadf0a89b8ee873497b54c5066));
        vk.gamma_abc[127] = Pairing.G1Point(uint256(0x19939cf3f66e262117ba51834da59eb4812eb01ec80ebc66731768315aded4d6), uint256(0x2ee9060a85c49b767da47480cd183ec89e4fe4f46212b20615aca8220e1e0d18));
        vk.gamma_abc[128] = Pairing.G1Point(uint256(0x13b72731e8c39f83fb2281614c267af81560d8762d95a36688af946f649319f5), uint256(0x1981d426e06cfc50782cf666e5d4cc6f42b146f711f364f264b36ed36d854e37));
        vk.gamma_abc[129] = Pairing.G1Point(uint256(0x2d8383c296b73a8612e3f803761b25c67a4906a66db9dd26a4ac049087f575f6), uint256(0x14a4f4c271da36a79c21c46831f1ad711dc4fa020bece8da28c64d069a8a90f6));
        vk.gamma_abc[130] = Pairing.G1Point(uint256(0x287d7df57547c8a1ce6e53bc259e798c96ba221f7858144b3adc7ee7d728ab10), uint256(0x0f525a067efe8de64c75c1bbfd46224f7d67bcb7c5f33fe92e775bfbe7cf15df));
        vk.gamma_abc[131] = Pairing.G1Point(uint256(0x053bc5c277f2f7676ca4ff825fb0f7abc790fa2abdd7c88b0f0db50dcde805f7), uint256(0x15f8ea7d03411fe9164d25d6577248df32b6158a9a1491575a131fb86368c9e7));
        vk.gamma_abc[132] = Pairing.G1Point(uint256(0x293404484ea7ac1a480418ca6dc853ecfbcfd9d537cf37cce61daaadcca50340), uint256(0x039a8453a4ed858cf7a96bd1f679b0b4dd30b097abe3fba808bbbbefceb7f3d4));
        vk.gamma_abc[133] = Pairing.G1Point(uint256(0x213ac7ea838e1d94e43b923f3df83c33d72eb841d501fca43ae1e2da9e4dedad), uint256(0x10cd25ccaaf150d864a3f0b2be6d2001c1f541de6ac57cd35a4fcca877b98977));
        vk.gamma_abc[134] = Pairing.G1Point(uint256(0x1a2799c1e299eb06c8ea538732a5c27452bcbbfe063c5460b30c6efc350f0bf8), uint256(0x01928231a97f934d4e8a3ab57888cb7aff915d0ada4d23d89ad31df7a2184b7d));
        vk.gamma_abc[135] = Pairing.G1Point(uint256(0x266170283ed1e15157adeeec2623ed20caf9f747d627ef10b08b9b817f3a9318), uint256(0x1328483f7ce2936f5247a8573f424e9313f2bb2f747367af5d8c9d208b481e94));
        vk.gamma_abc[136] = Pairing.G1Point(uint256(0x301c5196b754e4db75e58970bfc53804b9b08f37c06f02ab6f140870b2f0aef1), uint256(0x0334487fc2023004fdc82b16d721b97ec6937db690b2e0a4eecaccdf430f26c2));
        vk.gamma_abc[137] = Pairing.G1Point(uint256(0x07a06f6a1e3f651a95a38db0547ae58a8e658b7efd8000ee75385399d5375e26), uint256(0x2b83caa671c2af4774e233b0cc0174447a602e45c8798f27881345638a1bce3f));
        vk.gamma_abc[138] = Pairing.G1Point(uint256(0x05de366ef01675de3779c76491d84b4d4619f645421e4dcfdfe21f335409ebaa), uint256(0x16e816e5a19cb8fbea1eb35fd4f8bb983929fe21335445166bee9162c5ab6ca2));
        vk.gamma_abc[139] = Pairing.G1Point(uint256(0x240bc9830ee2c06c62953ac42b592dfdc39eefe231f21ea8c271cde85c259210), uint256(0x15172b69cfce1c063960e1a7bae2b04321dcf4c96e58d01e1ddda69d154f0c2e));
        vk.gamma_abc[140] = Pairing.G1Point(uint256(0x0bf5f7dfde5d8a0723e1d648400ab231b51c7b684a9c5af77f10953c174a7b3c), uint256(0x1383236de8b639399c3437f8f750baec645a3753fc33aa04e33af5cd3bfebf61));
        vk.gamma_abc[141] = Pairing.G1Point(uint256(0x27e118c55b158f065b3f5f3efd8d8fe03c625987762da4066c40bcc114cb343f), uint256(0x0aaf809aa01375b9d59af0413d65e53100be892262c0c27e6abb9e9ec6251577));
        vk.gamma_abc[142] = Pairing.G1Point(uint256(0x0c3558ed08e0763667c090bf24e3a3204c7369e79a990536c572d2ff8bf297ae), uint256(0x134ea3ba9906d1459a5e40e0ed918585cb2d133b917231a2a567ab3937a10a5f));
        vk.gamma_abc[143] = Pairing.G1Point(uint256(0x0a6955171fec4b582205df66df802204cbf3235422e2d7c4cb6d7fb4e99845cd), uint256(0x12d9f943dad89c9252f5ac0d5056ffbd2f00fc6ce97a0e0c4b10515f1edc4fba));
        vk.gamma_abc[144] = Pairing.G1Point(uint256(0x22392b343f31f4e7bd0dfd59933f97ef3fb3b27c35d7ccc47b7231b5faf38cb2), uint256(0x0fcdc8e036586b79d97026574b4c5c24b9f2de481d12cdcc5306f1e59b77ef57));
        vk.gamma_abc[145] = Pairing.G1Point(uint256(0x12747a05f416b7b882ac8b204875dab195bdaa3658cfb423afaa71658c667853), uint256(0x0e100114a6173c277df8ab5da7089d5b8701e2b4cff8e966f5bbc9d9d3de1d4f));
        vk.gamma_abc[146] = Pairing.G1Point(uint256(0x1dd101e5633f555e6789a05f84503f02b7d200f348a4963718e2a17a2e2f0e4f), uint256(0x1b3f7dca64a39b45299ee57732e7800ee4209874683307b9e2ac9fadbc2ae642));
        vk.gamma_abc[147] = Pairing.G1Point(uint256(0x27e2d226e8e05d7e084ded1765a5eb095d41335d0c21ee0d54795d4bc4980343), uint256(0x17c2acf2890a4dbce4a045a3528b90031d2b740c94c60d95df09b148b8136db3));
        vk.gamma_abc[148] = Pairing.G1Point(uint256(0x02eeff72339d8b82b800c5d5fae502ec0c57485586fdc671e7d4cb7794ec9c73), uint256(0x24d60fb2ea4db39e77aac3ffd6d6fcf156cc7425631b0eb86a5078821df0da58));
        vk.gamma_abc[149] = Pairing.G1Point(uint256(0x13b381badc33707d0d2c1277d9b1b8710db854b69bf94e607669399ed6c71767), uint256(0x0f76dbfd9bbcd326fb95ae3540891d2fa0f61cdaaa37acec0e7731872f2c88b0));
        vk.gamma_abc[150] = Pairing.G1Point(uint256(0x2b6e0ab4fc30c667b1ceb1cc13b737826660c5b0bd0730a4b8f94cfa2a858c55), uint256(0x1ce067d733ed499901c6d8bed67c78a8047db9c6380af9320950c079ada22d20));
        vk.gamma_abc[151] = Pairing.G1Point(uint256(0x2e3d5ec764c908f37f58ecabd5daeb45d658835692fa620335247e1448a53802), uint256(0x220e74ce960ea9745401c3d5a3222ae06dbd7e2e616c69d60e3299c1f689550d));
        vk.gamma_abc[152] = Pairing.G1Point(uint256(0x0a44976d752d0b4cc83246bf21cec46fe0c1a4074f541719e098c0a86138c165), uint256(0x0fa1fcfddfff80554525cbefdf297b1f45432119247a51953f2714c83c599855));
        vk.gamma_abc[153] = Pairing.G1Point(uint256(0x28f3d91d82e94faab1b4bb1cf5d33eb23e87ea9e7599bbd9f52bbcd0d4185ed6), uint256(0x27ccf4633efeb2a94862f7c1bbd061135ac049fe94c24a346c7578111f2c4301));
        vk.gamma_abc[154] = Pairing.G1Point(uint256(0x0b121629f8f8900d557148dc07c90743352966f636c6c31d68ff3238ba37bd6b), uint256(0x24ae378627d174ccedd8c7040e57a8513f96274fb87670cd613f0cb66589fa4b));
        vk.gamma_abc[155] = Pairing.G1Point(uint256(0x02ca8c26036e5009a40b52995672d883bb23c40c7acddd185732c6339bcf22b1), uint256(0x1dbdc0851676f8b83f844c0b02acf27426f206a5a7696a3471b9dca80a8bb601));
        vk.gamma_abc[156] = Pairing.G1Point(uint256(0x1e414e037212ed6c475cfaff0af1289dfd2f4d46270d9118653b2376713375b5), uint256(0x0c73f85d39d1c849eef67dab774d3479696abb060070c291054ed64a4815cae2));
        vk.gamma_abc[157] = Pairing.G1Point(uint256(0x18fadfd3f12d5c0312319d4ea70a7a801effb00f50e3e58fae3195ec0dfd3394), uint256(0x2a8f508f582c68eb3823503f93c070c86a2bebc73943d25442d2d350ad1dd3ac));
        vk.gamma_abc[158] = Pairing.G1Point(uint256(0x2aa173965c995316a922b17792907d88a722167c107de4c6475ca98e011e5ddf), uint256(0x156919b92b9b6531844026451ccf0ea0e9c46e0cdb32ef133a42fc5c6719fe3b));
        vk.gamma_abc[159] = Pairing.G1Point(uint256(0x1f203f34d995df8ef037ab6999879956f6d46bbe102c987ee140c1e0f26338cb), uint256(0x2ed7d8bfb562ad3569bc5cf1424cd7ba53df7380890999c43343a7435556ce02));
        vk.gamma_abc[160] = Pairing.G1Point(uint256(0x2ad0cc5a9fa82808c328ff32a9143fd87eb1769a37e629f87bc34e844ccb8532), uint256(0x0781f9e2abf7bc1c1424121e99b75e7c094a2d11fdab097b4b4de8ed88445901));
        vk.gamma_abc[161] = Pairing.G1Point(uint256(0x1daad83720dc344a9d976b97d1c468bd72178865c1135913ebd44ad463f9cc32), uint256(0x1e8389f50ff1ea953ee3f398b3586a684933a7545b20f91889f003443365d2ed));
        vk.gamma_abc[162] = Pairing.G1Point(uint256(0x22db400879cbbdeeb49813bb294ae9d29bd958a536b2bd6f648e681a80869a4a), uint256(0x0f7e80719e3653328aa7dd365f1a70bacc28bd3f00ec58cddfb056f0a7a17469));
        vk.gamma_abc[163] = Pairing.G1Point(uint256(0x0a5f522db204012adbd713b80dc6f755b469b4db96a05831becbe7fe07221892), uint256(0x2bd48ab846126161621691ddca8e5fba0c6e32ee7479d9d0ddb94b91c20b4218));
        vk.gamma_abc[164] = Pairing.G1Point(uint256(0x09fbb6cd9f0a9c6216632728afdd704e5d897059723302fba0767341df9ebbee), uint256(0x2b5ec3378655bf42adea3c42d6614c3af527a1b65e31d2cd92a741c552627e36));
        vk.gamma_abc[165] = Pairing.G1Point(uint256(0x2603b69e1ddab54daf2bc181c300d7deb43095bc212618e92ca422c4d73bf2ce), uint256(0x27d4c6c6c4d0cdd365bd2e4b9d456058da945f14bb4156a265611872c0fef3d6));
        vk.gamma_abc[166] = Pairing.G1Point(uint256(0x11523c7058cc5165bb9e9aaa66ac80fde3fb34ccc1e30027ff71c5748e89f250), uint256(0x19aad4be9af80ef21cb44061be009a05dca97cd10bbfb9e0cdf3b1cadcae5bfb));
        vk.gamma_abc[167] = Pairing.G1Point(uint256(0x2ab43c3c91cd1f95903353eddb7745a96480ba708e9b1acb078c85cc44694cd8), uint256(0x253f69815dd3b88b37979d529b89a3e908878fb1c33cbdffe9cf6225222cc646));
        vk.gamma_abc[168] = Pairing.G1Point(uint256(0x07325f3ac86b74945e1f08ce9095ecaf010deb1c9071e5aebf7c3243f87b102d), uint256(0x0cbaebc7c0b986a65ca7d592b6930e5cc547ff923043de28a3189380b49bb0f6));
        vk.gamma_abc[169] = Pairing.G1Point(uint256(0x108ed6ba6e1b64f6c4417f4886e3fe1c705f217e92e83af4fc18f5302c4834ae), uint256(0x2295a0316934e0d58187884d35e2be223796a55c7a095019d607991af22fe2db));
        vk.gamma_abc[170] = Pairing.G1Point(uint256(0x0131921e13c8cf484e5e251a6e059f7d4c1d13aa78a4db50b0db09e21b43a678), uint256(0x1cdf94861f7656f309940e19f6314d72ec7efc4c0cc21ceb38bf386488f8d062));
        vk.gamma_abc[171] = Pairing.G1Point(uint256(0x259e7bf27ebdf465b27130c9e40fb60567cf7b9caf4fba1532922abbdc5de9fd), uint256(0x1a359913b04c81793c59c13c00258e971f9c89d3237de1365cb7c0074f36f86d));
        vk.gamma_abc[172] = Pairing.G1Point(uint256(0x14e4ddb51dcd0d96de6cc9545406d98eaf5cbbd8d9095a9fec427e2817b75b86), uint256(0x1a74c82f0e9829ea625e7a0e09a1f5583058c8294524a6ccfe8429e2b2b823a1));
        vk.gamma_abc[173] = Pairing.G1Point(uint256(0x29964879b73de35656a0983785cf3abd9dd632deea3b7ba644b563db4eb94da7), uint256(0x14b1ee566d377f54f429723c14b8c0eb41d0972872caee828c02d73785077182));
        vk.gamma_abc[174] = Pairing.G1Point(uint256(0x0cc090b2958d199368f1e81938a5ea1782cad87546b414574c44eccafd1d4c53), uint256(0x29ad27295dce99e104b31c12efa4b18e7acf5c0b6d612a47b5455c35871d4dbf));
        vk.gamma_abc[175] = Pairing.G1Point(uint256(0x2a75242a8d476770b9619407cdfdc351612d1f2ecdf2b5d71a2a589ea592049e), uint256(0x01b661d76eb5ffeb9930d0f2d847005d179786d161ad4e44e208c2e2117c009d));
        vk.gamma_abc[176] = Pairing.G1Point(uint256(0x0e604852fe9a613dabf45a5788bd512847ffb1fb4b5017f19619ce04c3dcf536), uint256(0x2a30a9bfcadb579a98b70487cd57ea8845c3185567575266c3688fd831d88653));
        vk.gamma_abc[177] = Pairing.G1Point(uint256(0x168b28729748695553693d3f606ef1450f02ce5c91b71bb05981b9bf8a6d7c52), uint256(0x08cc14f66a3817636a20a197af6cbcbf4845df63bfe5ff834137439cd2e1db40));
        vk.gamma_abc[178] = Pairing.G1Point(uint256(0x19c29a1dff119161529ccf722e808c1b3a989628b923be6205f242312ecf9972), uint256(0x1f9979eed6779861a2359c3895516443c733854a9fd1d542ca1d1fe8adc1dbc4));
        vk.gamma_abc[179] = Pairing.G1Point(uint256(0x1d5ee65eb200baa5201bbd9ec191242cc01abe0f26ff41e4f5bb59dea9878156), uint256(0x030808f120b36313e9655bc4e8d2788be5e3d477b6a5d7d4d5bd80de35b7ccf7));
        vk.gamma_abc[180] = Pairing.G1Point(uint256(0x19de376dc8c1a09ff8a8a56a8788b09440a6ff50519146e1be0f96f5abe5726d), uint256(0x14ab5cbed575c580f2583c0f5f17d7de122eb1e555f355e4287bed5124352cc5));
        vk.gamma_abc[181] = Pairing.G1Point(uint256(0x2bd0c4dbdc2ddf31f19665b6b762630074231525689843faa5f2e1aa88117bd4), uint256(0x0357b386a862efb656c779b6b9a36edac54f9d392a6a171341a4aaca94c2d6d6));
        vk.gamma_abc[182] = Pairing.G1Point(uint256(0x1a16a399d2eda7ff9825376c416bc60ead5f7f077f47dc387fef32be311b4aa3), uint256(0x20a31822448571963008dca4d09f5a123a360c5162c93aad8ec993895a856ae3));
        vk.gamma_abc[183] = Pairing.G1Point(uint256(0x203d86acbfdb549ffac93e5dd64a49d61961d661036d195e3c061c1cb59665ef), uint256(0x2445aa45b07d5008dad1a2b69a186cc9afc5c84557b52796eafc9c07881cb7d7));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[183] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](183);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
