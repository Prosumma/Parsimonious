// swiftlint:disable file_length line_length
//
//  JSON.swift
//  ParsimoniousTests
//
//  Created by Gregory Higley on 2020-03-12.
//
//  Licensed under the MIT license: https://opensource.org/licenses/MIT
//  Permission is granted to use, copy, modify, and redistribute the work.
//  Full license information available in the project LICENSE file.
//

import Foundation

let rawJSON = """
[
    {
        "_id": "5cb1ac59a0b5bb0bda2e020f",
        "index": 0,
        "guid": "dbe4acf1-8a8b-4de6-b082-d41390fb1eef",
        "isActive": true,
        "balance": "$1,035.18",
        "picture": "http://placehold.it/32x32",
        "age": 31,
        "eyeColor": "brown",
        "name": {
            "first": "Stokes",
            "last": "Burnett"
        },
        "company": "ASSURITY",
        "email": "stokes.burnett@assurity.biz",
        "phone": "+1 (846) 578-3702",
        "address": "578 Otsego Street, Hendersonville, Rhode Island, 9601",
        "about": "Quis nostrud exercitation magna exercitation minim sint officia ad voluptate mollit pariatur id sunt. Nostrud dolor nulla mollit aliquip Lorem deserunt consequat eiusmod aute sunt. Dolore non labore enim aliqua non veniam aliquip. Nisi ullamco minim id ut aliquip laborum ullamco officia nostrud elit. Dolore amet quis tempor proident commodo. Dolore labore enim aliqua veniam amet veniam consectetur. Ad laboris id irure aliqua cillum magna.",
        "registered": "Monday, February 10, 2014 7:32 AM",
        "latitude": "55.256457",
        "longitude": "175.711907",
        "tags": [
            "ex",
            "in",
            "velit",
            "id",
            "pariatur"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "sizes": null,
        "friends": [
            {
                "id": 0,
                "name": "Lilly Velasquez"
            },
            {
                "id": 1,
                "name": "Juliet Jennings"
            },
            {
                "id": 2,
                "name": "Tyson Meyer"
            }
        ],
        "greeting": "Hello, Stokes! You have 10 unread messages.",
        "favoriteFruit": "apple"
    },
    {
        "_id": "5cb1ac59a0f67f22d6ec54cd",
        "index": 1,
        "guid": "dbe71e5a-06d0-461c-bd61-0df6751dc403",
        "isActive": false,
        "balance": "$3,612.18",
        "picture": "http://placehold.it/32x32",
        "age": 22,
        "eyeColor": "brown",
        "name": {
            "first": "Selma",
            "last": "Woods"
        },
        "company": "ENORMO",
        "email": "selma.woods@enormo.name",
        "phone": "+1 (966) 563-3324",
        "address": "957 Tiffany Place, Homestead, Illinois, 5772",
        "about": "Cupidatat mollit nostrud culpa consequat eiusmod. Excepteur voluptate sint veniam voluptate laboris aliquip. Exercitation nisi commodo laborum in cupidatat. Dolore cillum adipisicing pariatur dolor ipsum. Pariatur eu minim excepteur culpa reprehenderit qui elit. Mollit qui ullamco laboris quis eiusmod dolore culpa voluptate occaecat deserunt tempor consectetur laborum consectetur.",
        "registered": "Wednesday, December 2, 2015 3:48 AM",
        "latitude": "-46.031107",
        "longitude": "-55.104009",
        "tags": [
            "labore",
            "deserunt",
            "eiusmod",
            "laboris",
            "laboris"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Katheryn Duncan"
            },
            {
                "id": 1,
                "name": "Shauna Brewer"
            },
            {
                "id": 2,
                "name": "Hillary Good"
            }
        ],
        "greeting": "Hello, Selma! You have 9 unread messages.",
        "favoriteFruit": "apple"
    },
    {
        "_id": "5cb1ac593a83c7170e33a258",
        "index": 2,
        "guid": "a92eb1bc-303e-4a74-9d76-b43a99413b53",
        "isActive": false,
        "balance": "$3,332.50",
        "picture": "http://placehold.it/32x32",
        "age": 21,
        "eyeColor": "brown",
        "name": {
            "first": "Jill",
            "last": "Sawyer"
        },
        "company": "TELEPARK",
        "email": "jill.sawyer@telepark.net",
        "phone": "+1 (868) 518-3824",
        "address": "802 Hazel Court, Golconda, Delaware, 3132",
        "about": "Dolore excepteur quis cillum nisi nulla. Velit duis ex voluptate duis cupidatat do incididunt. Velit esse sunt qui velit incididunt non pariatur. Consectetur aute commodo enim laboris cupidatat nisi qui et.",
        "registered": "Sunday, October 25, 2015 8:35 PM",
        "latitude": "-76.818271",
        "longitude": "-16.974169",
        "tags": [
            "aliquip",
            "aliqua",
            "cupidatat",
            "eu",
            "ullamco"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Rosario Parks"
            },
            {
                "id": 1,
                "name": "Johanna Hartman"
            },
            {
                "id": 2,
                "name": "Adrienne Velazquez"
            }
        ],
        "greeting": "Hello, Jill! You have 7 unread messages.",
        "favoriteFruit": "apple"
    },
    {
        "_id": "5cb1ac59370f8359fd7fa815",
        "index": 3,
        "guid": "4f73c74f-fe2c-46c3-a8d7-b9c5ced79d58",
        "isActive": true,
        "balance": "$2,518.02",
        "picture": "http://placehold.it/32x32",
        "age": 40,
        "eyeColor": "brown",
        "name": {
            "first": "Bobbi",
            "last": "Richardson"
        },
        "company": "IDEALIS",
        "email": "bobbi.richardson@idealis.io",
        "phone": "+1 (922) 454-2547",
        "address": "255 Heath Place, Glendale, Wisconsin, 7924",
        "about": "Occaecat reprehenderit cupidatat cupidatat amet commodo labore et proident reprehenderit occaecat eu. Nulla irure excepteur ullamco laborum est ea officia magna deserunt commodo incididunt minim ipsum irure. Adipisicing laborum ipsum veniam elit. Eiusmod incididunt sit sit laboris velit veniam. Tempor id et nostrud ea dolor id ad laborum laboris fugiat. Magna commodo adipisicing eiusmod dolore. Tempor nostrud Lorem duis ea sunt anim velit pariatur.",
        "registered": "Wednesday, December 7, 2016 10:57 AM",
        "latitude": "5.006509",
        "longitude": "-103.933765",
        "tags": [
            "culpa",
            "veniam",
            "aute",
            "do",
            "eiusmod"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Davenport Tanner"
            },
            {
                "id": 1,
                "name": "Cheri Hopper"
            },
            {
                "id": 2,
                "name": "Yvonne Stein"
            }
        ],
        "greeting": "Hello, Bobbi! You have 5 unread messages.",
        "favoriteFruit": "strawberry"
    },
    {
        "_id": "5cb1ac590c017635219b92d4",
        "index": 4,
        "guid": "c6f2bddb-fbd8-4ab3-9a22-337758af2dd4",
        "isActive": true,
        "balance": "$3,062.80",
        "picture": "http://placehold.it/32x32",
        "age": 22,
        "eyeColor": "brown",
        "name": {
            "first": "Clarice",
            "last": "Klein"
        },
        "company": "CORPULSE",
        "email": "clarice.klein@corpulse.info",
        "phone": "+1 (930) 468-3832",
        "address": "261 Dover Street, Lloyd, Louisiana, 8406",
        "about": "Voluptate ad dolor sint laborum est non aute duis. Lorem consequat irure esse cillum nostrud duis voluptate sunt eu quis deserunt incididunt sit ex. Ea sunt eu et reprehenderit eiusmod tempor magna dolor sunt id duis duis. Excepteur et qui cupidatat elit.",
        "registered": "Sunday, May 4, 2014 8:53 PM",
        "latitude": "-36.770864",
        "longitude": "169.47629",
        "tags": [
            "commodo",
            "pariatur",
            "sit",
            "in",
            "incididunt"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Desiree Gentry"
            },
            {
                "id": 1,
                "name": "Leigh Erickson"
            },
            {
                "id": 2,
                "name": "Benson Haynes"
            }
        ],
        "greeting": "Hello, Clarice! You have 10 unread messages.",
        "favoriteFruit": "banana"
    },
    {
        "_id": "5cb1ac59668773e4a4dd0643",
        "index": 5,
        "guid": "1a3ca4cf-9386-4e9c-a197-36a60a8f49ae",
        "isActive": true,
        "balance": "$2,342.96",
        "picture": "http://placehold.it/32x32",
        "age": 29,
        "eyeColor": "brown",
        "name": {
            "first": "Banks",
            "last": "Munoz"
        },
        "company": "SEALOUD",
        "email": "banks.munoz@sealoud.me",
        "phone": "+1 (944) 502-2393",
        "address": "203 Ford Street, Jenkinsville, Massachusetts, 5756",
        "about": "Duis sint culpa amet consequat minim ea qui commodo id deserunt Lorem anim nostrud. Cillum minim qui aliqua qui. Excepteur dolor cupidatat commodo eiusmod adipisicing dolore quis ut. Quis proident tempor nostrud anim aliqua cillum nulla reprehenderit cupidatat eiusmod duis in commodo. Consectetur ex sunt aliquip in culpa.",
        "registered": "Saturday, April 11, 2015 11:40 PM",
        "latitude": "-43.715366",
        "longitude": "17.065306",
        "tags": [
            "magna",
            "cupidatat",
            "labore",
            "pariatur",
            "aliqua"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Harrell Edwards"
            },
            {
                "id": 1,
                "name": "Gwen Savage"
            },
            {
                "id": 2,
                "name": "Carney Bryan"
            }
        ],
        "greeting": "Hello, Banks! You have 9 unread messages.",
        "favoriteFruit": "strawberry"
    },
    {
        "_id": "5cb1ac59640540b2fd36d272",
        "index": 6,
        "guid": "6ba6aa5f-cb97-46ac-bd42-f7a3400c551b",
        "isActive": true,
        "balance": "$3,147.15",
        "picture": "http://placehold.it/32x32",
        "age": 20,
        "eyeColor": "brown",
        "name": {
            "first": "Fannie",
            "last": "Clay"
        },
        "company": "QUALITERN",
        "email": "fannie.clay@qualitern.tv",
        "phone": "+1 (980) 561-2010",
        "address": "847 Chase Court, Saddlebrooke, Hawaii, 5730",
        "about": "Deserunt magna dolore consequat deserunt. Et aute nulla eiusmod deserunt ipsum minim aute aliquip exercitation commodo duis qui. Tempor esse consequat fugiat in anim.",
        "registered": "Thursday, December 22, 2016 1:28 PM",
        "latitude": "-25.481354",
        "longitude": "124.491264",
        "tags": [
            "Lorem",
            "proident",
            "non",
            "officia",
            "id"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Robertson Shelton"
            },
            {
                "id": 1,
                "name": "Walter Barnes"
            },
            {
                "id": 2,
                "name": "Wilson Perkins"
            }
        ],
        "greeting": "Hello, Fannie! You have 7 unread messages.",
        "favoriteFruit": "apple"
    },
    {
        "_id": "5cb1ac59fb6ec579fe558cf0",
        "index": 7,
        "guid": "bf1661b5-5411-4b02-9c76-33b4adbf1e64",
        "isActive": false,
        "balance": "$3,900.98",
        "picture": "http://placehold.it/32x32",
        "age": 23,
        "eyeColor": "brown",
        "name": {
            "first": "Pope",
            "last": "Finley"
        },
        "company": "DRAGBOT",
        "email": "pope.finley@dragbot.org",
        "phone": "+1 (825) 488-3843",
        "address": "516 Dahl Court, Sharon, Mississippi, 1703",
        "about": "Nulla ad ea aliqua id. Eiusmod adipisicing ex proident et ullamco commodo sunt pariatur officia aute. Eiusmod esse magna non voluptate reprehenderit aute cupidatat do enim excepteur tempor sit. Qui incididunt incididunt et sint laboris proident ea cillum sit voluptate nostrud aute.",
        "registered": "Saturday, March 30, 2019 3:56 AM",
        "latitude": "-3.657646",
        "longitude": "-130.506407",
        "tags": [
            "aliquip",
            "nostrud",
            "est",
            "fugiat",
            "in"
        ],
        "range": [
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9
        ],
        "friends": [
            {
                "id": 0,
                "name": "Ellis Mcdonald"
            },
            {
                "id": 1,
                "name": "Moran Hutchinson"
            },
            {
                "id": 2,
                "name": "Gentry Jackson"
            }
        ],
        "greeting": "Hello, Pope! You have 10 unread messages.",
        "favoriteFruit": "banana"
    }
]
"""
