import { Socket, createServer } from "net";
import { encodeMessage, processBuffer, type WireMessage } from "./wire-lib.js";
import { ObjectId } from "bson";
import assert from "assert";

const HOST = '127.0.0.1';
const PORT = 9000;

const server = createServer(handleNewConnection);

async function handleNewConnection(sock: Socket) {
  console.log('client connected from port:', sock.remotePort);

  const bufHolder = { buf: Buffer.alloc(0) };

  sock.on('data', async (data) => {
    bufHolder.buf = Buffer.concat([bufHolder.buf, data]);
    const messages = processBuffer(bufHolder);
    for (const message of messages) {
      console.log(`C -> S message`, message.header);
      console.dir(message.payload, { depth: null });
      const responseBuf = await getEncodedResponse(message);
      sock.write(responseBuf);
    }
  });
}

server.listen(PORT, () => {
  console.log(`Custom Mongo Server listening on`, `${HOST}:${PORT}`);
});

async function getEncodedResponse(message: WireMessage): Promise<Buffer> {
  const response = await getResponse(message);
  const responseBuf = encodeMessage(response);

  return responseBuf;
}

async function getResponse(message: WireMessage): Promise<WireMessage> {
  const { header, payload } = message;
  const { opCode, requestID, responseTo } = header;

  if (opCode === 2004) {
    return {
      header: {
        messageLength: 0, // will be calculated by encoder
        requestID: 1, // TODO: Unhardcode
        responseTo: requestID,
        opCode: 1, // OP_REPLY
      },
      payload: {
        _type: 'OP_REPLY',
        responseFlags: 8,
        cursorID: 0n,
        startingFrom: 0,
        numberReturned: 1,
        documents: [
          {
            helloOk: true,
            ismaster: true,
            topologyVersion: {
              processId: new ObjectId(),
              counter: 0,
            },
            maxBsonObjectSize: 16777216,
            maxMessageSizeBytes: 48000000,
            maxWriteBatchSize: 100000,
            localTime: new Date().toISOString(),
            logicalSessionTimeoutMinutes: 30,
            connectionId: 1,
            minWireVersion: 0,
            maxWireVersion: 21,
            readOnly: false,
            ok: 1
          },
        ]
      }
    };
  } else if (opCode === 2013) {
    if (payload._type !== 'OP_MSG') throw new Error('Invalid payload');
    const { sections } = payload;

    const body = sections[0];
    const additionalSections = sections.slice(1);

    if (body?.sectionKind !== 0) throw new Error('Invalid body section');
    if (additionalSections.length > 0) throw new Error('Section kind 1 not yet handled');

    const { document } = body;

    if (document.buildInfo) {
      return {
        header: {
          messageLength: 0,
          requestID: 1,
          responseTo: requestID,
          opCode,
        },
        payload: {
          _type: 'OP_MSG',
          flagBits: 0,
          sections: [{
            sectionKind: 0,
            document: {
              version: 'x',
              gitVersion: 'x',
              // modules: [],
              // allocator: 'x',
              // javascriptEngine: 'x',
              // sysInfo: 'x',
              // versionArray: [],
              // openssl: {
              //   running: 'x',
              //   compiled: 'x'
              // },
              // b

              ok: 1,
            }
          }]
        },
      }
    } else {
      return {
        header: {
          messageLength: 0,
          requestID: 1,
          responseTo: requestID,
          opCode: 2013,
        },
        payload: {
          _type: 'OP_MSG',
          flagBits: 0,
          sections: [{
            sectionKind: 0,
            document: {
              ok: 0,
              errmsg: `no such command`,
              code: 59,
              codeName: 'CommandNotFound',
            }
          }]
        }
      }
    }


    
  }

  throw new Error(`Could not handle requestID: ${requestID}`);
}