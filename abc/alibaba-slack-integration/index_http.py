import logging
import requests
import json
import urllib.parse

# Pretty-print and properly escape the JSON
# text passed to us by CloudMonitor, so that
# we can display it in Slack
def pprint_json(leading_char, parsed_json):
    output_text = '\n'

    for key in parsed_json:
        item = parsed_json[key]

        if isinstance(item, dict): # We need to go deeper!
            output_text += key + ':'
            output_text += pprint_json(leading_char + '\t', item)
        else:
            output_text += "{}{}: {}\n".format(leading_char, key, item)

    return output_text

# Function body: takes JSON from CloudMonitor callbacks and sends it on to 
# Slack as properly formatted displayable text
def handler(environ, start_response):
    logger = logging.getLogger()

    context = environ['fc.context']
    request_uri = environ['fc.request_uri']

    # This is left in as an example of how you would process
    # request parameters. We don't use it as we are only
    # interested in the body of the POST received from
    # CloudMonitor
    for k, v in environ.items():
      if k.startswith('HTTP_'):
        # process custom request headers
        pass

    # Parse JSON and then POST to Slack Webhook
    try:
      request_body_size = int(environ.get('CONTENT_LENGTH', 0))
    except (ValueError):
      request_body_size = 0
  
    request_body = environ['wsgi.input'].read(request_body_size)

    # Decode the URL-encoded parameters passed by CloudMonitor
    try:
      request_body_string = urllib.parse.unquote(request_body.decode())
    except:
      output = "Uh oh! Unable to decode and unquote the URL-formatted request body...check your Function Compute logs."

    try:
      request_body_json = urllib.parse.parse_qs(request_body_string)
    except: 
      output = "Uh oh! Unable to parse the URL query string parameters passed by CloudMonitor...check your Function Compute logs."

    try:
      output = pprint_json('', request_body_json)
    except:
      output = "Uh oh! Couldn't pretty-print the JSON passed to us by CloudMonitor...check your Function Compute logs."

    # Log the request that we received, for debugging purposes
    logger.info(request_body)

    # URL of the Slack webhook
    end_url = 'https://hooks.slack.com/services/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'
    headers = {'Content-type': 'application/json'}

    # Send message to slack
    payload = {'text': output}
    r = requests.post(end_url,headers=headers, data=json.dumps(payload))

    # Send response (to indicate success or failure in posting to slack)
    # FIXME: Use status from variable 'r' here to indicate success or failure communicating
    # with slack
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    # Output formatted text for debugging purposes
    return [output.encode()]
