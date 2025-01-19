import json
import os
import random
import uuid

import boto3
import requests

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.getenv("DYNAMODB_TABLE"))

def lambda_handler(event, context):
    unique_id = str(uuid.uuid4())
    # Get the Pokémon name from the event
    path_parameters = event.get("pathParameters", {})
    if not path_parameters:
        raise ValueError("Missing pathParameters in the request.")
    
    pokemon_name = path_parameters.get("pokemon_name")
    if not pokemon_name:
        raise ValueError("Missing 'pokemon_name' in pathParameters.")
    
    pokemon_name = pokemon_name.lower()

    # Build the PokeAPI URL
    api_url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_name}"

    # Send a request to the PokeAPI
    try:
        response = requests.get(api_url)
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

    # Parse the response from PokeAPI
    data = response.json()
    color_random = random.random()

    important_data = {
        'ID': unique_id,
        'name': data['name'],
        'abilities': [{'name': ability['ability']['name']} for ability in data['abilities']],
        'types': [{'name': type['type']['name']} for type in data['types']],
        'height': data['height'],
        'weight': data['weight'],
        'sprites': {
            'selected_sprite': data['sprites']['front_shiny'] if color_random < 0.2 else data['sprites']['front_default']
        }
    }

    table.put_item(Item=important_data)

    # Return the important data
    return {
        'statusCode': 200,
        'body': "Pokemon saved successfully"
        }