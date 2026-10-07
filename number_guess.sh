#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

printf 'Enter your username:\n'
read -r username
sql_username=$(printf '%s' "$username" | sed "s/'/''/g")
player_stats=$($PSQL "SELECT games_played || '|' || best_game FROM players WHERE username='$sql_username'")

if [[ -n $player_stats ]]; then
	IFS='|' read -r games_played best_game <<< "$player_stats"
	printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$username" "$games_played" "$best_game"
	returning_player=true
else
	printf 'Welcome, %s! It looks like this is your first time here.\n' "$username"
	returning_player=false
fi

secret_number=$((RANDOM % 1000 + 1))
guess_count=0

printf 'Guess the secret number between 1 and 1000:\n'
while read -r guess
do
	if ! [[ $guess =~ ^[0-9]+$ ]]; then
		printf 'That is not an integer, guess again:\n'
		continue
	fi

	guess_value=$((10#$guess))
	guess_count=$((guess_count + 1))
	if (( guess_value < secret_number )); then
		printf "It's higher than that, guess again:\n"
	elif (( guess_value > secret_number )); then
		printf "It's lower than that, guess again:\n"
	else
		printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$guess_count" "$secret_number"
		if [[ $returning_player == true ]]; then
			$PSQL "UPDATE players SET games_played = games_played + 1, best_game = LEAST(best_game, $guess_count) WHERE username='$sql_username'" > /dev/null
		else
			$PSQL "INSERT INTO players (username, games_played, best_game) VALUES ('$sql_username', 1, $guess_count)" > /dev/null
		fi
		break
	fi
done
