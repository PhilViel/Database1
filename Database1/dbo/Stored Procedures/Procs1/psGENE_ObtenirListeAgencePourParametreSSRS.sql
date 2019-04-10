
/****************************************************************************************************
Code de service		:		psGENE_ObtenirListeAgencePourParametreSSRS
Nom du service		:		psGENE_ObtenirListeAgencePourParametreSSRS 
But					:		fournir la liste des agences comme paramètre de rapport SSRS
Facette				:		GENE 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
                        @bInclureTous	            Indique si on veut avoir la veleur "Tous les titres" dans le premier élément de la liste

Exemple d'appel:
                EXEC psGENE_ObtenirListeAgencePourParametreSSRS

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------

Historique des modifications :			
						Date						Programmeur								Description							Référence
						2018-06-18					Donald Huppé							Création du service
 ****************************************************************************************************/

CREATE PROCEDURE psGENE_ObtenirListeAgencePourParametreSSRS
AS
	BEGIN
		SET NOCOUNT ON

SELECT *
FROM (
	SELECT
		Sort = 0,
		BossID = 0,
		Agence = 'Toutes les agences'

	UNION ALL

	SELECT 
		Sort = DENSE_RANK() OVER (
							ORDER BY HB.LastName, HB.FirstName
														),
		BossID = R.RepID,
		Agence = HB.FirstName + ' ' + HB.LastName
	FROM Un_Rep R
	JOIN Mo_Human HB on HB.HumanID = R.RepID
	WHERE R.RepID in (
							149593,--	5852--Martin Mercier
							149489,--	6070--Clément Blais
							149521,--	6262--Michel Maheu
							436381	--	7036--Sophie Babeux
							)
	)V

	ORDER BY V.Sort
			
	END
