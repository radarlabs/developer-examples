/**
 * Sends SMS message with Twilio
 */
async function sendText(params, settings) {
   const accountId = 'MY_TWILIO_ACCOUNT_ID';
   const token = 'MY_TWILIO_TOKEN';
   const endpoint = `https://api.twilio.com/2010-04-01/Accounts/${accountId}/Messages.json`;
   await fetch(endpoint, {
        method: 'POST',
        headers: {
               Authorization: `Basic ${btoa(accountId + ':' + token)}`,
               'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
             },
        body: toFormParams(params)
      });
}

function toFormParams(params) {
   return Object.entries(params)
     .map(([key, value]) => {
            const paramName = encodeURIComponent(key);
            const param = encodeURIComponent(value);
            return `${paramName}=${param}`;
          })
     .join('&');
}
