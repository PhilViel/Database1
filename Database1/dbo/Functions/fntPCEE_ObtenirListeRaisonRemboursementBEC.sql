/****************************************************************************************************
Code de service		:		fntPCEE_ObtenirListeRaisonRemboursementBEC
Nom du service		:		1.1.1 Obtenir la liste des raisons de remboursement BEC
But					:		Afficher les raisons de remboursement du BEC
Description			:		Ce service affiche les raisons valables pour un remboursement du BEC au PCEE par
							l'outil de gestion du BEC
Facette				:		PCEE
Reférence			:		Document fntPCEE_ObtenirListeRaisonRemboursementBEC.DOCX

Parametres d'entrée :	Parametres					Description									Obligatoire
                        ----------                  ----------------							--------------                       
						Aucun

Exemples d'appel:
				SELECT * FROM dbo.fntPCEE_ObtenirListeRaisonRemboursementBEC()

Parametres de sortie :  Table						Champs										Description
					    -----------------			---------------------------					--------------------------
						Un_CESP400WithdrawReason	tiCESP400WithdrawReasonID					Code la raison du remboursement

													vcCESP400WithdrawReason						Description de la raison
Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-16					Jean-François Gauthier					Création de la fonction
						2009-11-23					Jean-François Gauthier					Utilisation du champ bIsBECWithdrawReason dans le Where
 ****************************************************************************************************/

CREATE FUNCTION [dbo].[fntPCEE_ObtenirListeRaisonRemboursementBEC]()
RETURNS @tRaison TABLE
			(
				tiIDCESP400RaisonRemboursement		TINYINT
				,vcCESP400DescriptionRemboursement	VARCHAR(200)
			)
AS
	BEGIN
		INSERT INTO @tRaison
		(
			r.tiIDCESP400RaisonRemboursement	
			,r.vcCESP400DescriptionRemboursement
		)
		SELECT
			tiCESP400WithdrawReasonID
			,vcCESP400WithdrawReason
		FROM
			dbo.Un_CESP400WithdrawReason r
		WHERE
			r.bIsBECWithdrawReason	= 1		-- RÉCUPÈRE UNIQUE LES RAISONS LIÉES AU BEC
		ORDER BY
			r.vcCESP400WithdrawReason

		RETURN
	END
