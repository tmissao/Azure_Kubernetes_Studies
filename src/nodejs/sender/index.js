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