const { QueueServiceClient } = require("@azure/storage-queue");
const { DefaultAzureCredential } = require("@azure/identity");

const credential = new DefaultAzureCredential();

const account = "storagemissaoterraform";
const queueServiceClient = new QueueServiceClient(
  `https://${account}.queue.core.windows.net`,
  credential
);

const queueName = "queue-1";
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