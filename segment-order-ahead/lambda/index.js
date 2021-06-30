async function onTrack(event, settings) {
  const validEvent = event.event === 'Trip Arrived Destination';
  const Body = 'Your 🍔 is ready!';
  const To = event.properties && event.properties.trip_metadata_Phone;
  const From = 'TWILIO_PHONE_NUMBER';

  if (validEvent && From && To) {
    await sendText(
      {
        From,
        To,
        Body
      },
      settings
    );
  }
}

async function sendText(params, settings) {
  const accountId = 'TWILIO_ACCOUNT_ID';
  const token = 'TWILIO_AUTH_TOKEN';
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

