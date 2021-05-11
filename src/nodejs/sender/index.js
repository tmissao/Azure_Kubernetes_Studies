const { QueueServiceClient } = require("@azure/storage-queue");
const account = "storagemissaoterraform";
const sas = "?sv=2020-02-10&ss=q&srt=so&sp=raup&se=2021-05-17T23:08:03Z&st=2021-05-11T15:08:03Z&spr=https,http&sig=I9kkVpJGq3z2wCizBZ6mTakU6O2JcqdWmL4VKUe%2BtE8%3D";
const queueServiceClient = new QueueServiceClient(
  `https://${account}.queue.core.windows.net${sas}`
);

const queueName = "missao-queue-1";
const queueClient = queueServiceClient.getQueueClient(queueName);

run = async() => {
  let index = 0;
  while(true) {
    try {
      const sendMessageResponse = await queueClient.sendMessage(`Hello World! #${index++}`);
      console.log(
        `Sent message successfully, service assigned message Id: ${sendMessageResponse.messageId}, service assigned request Id: ${sendMessageResponse.requestId}`
      );
    } catch (e) {
      console.error(e)
    }
  }
}

run();