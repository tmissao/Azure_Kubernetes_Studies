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
      const response = await queueClient.receiveMessages();
      if (response.receivedMessageItems.length == 1) {
        const receivedMessageItem = response.receivedMessageItems[0];
        console.log(`Processing & deleting message with content: ${receivedMessageItem.messageText}`);
        const deleteMessageResponse = await queueClient.deleteMessage(
          receivedMessageItem.messageId,
          receivedMessageItem.popReceipt
        );
        console.log(
          `Delete message successfully, service assigned request Id: ${deleteMessageResponse.requestId}`
        );
      }
    } catch (e) {
      console.error(e)
    }
  }
}

run();