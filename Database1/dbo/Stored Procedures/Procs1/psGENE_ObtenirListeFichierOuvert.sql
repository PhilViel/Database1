/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirListeFichierOuvert
Nom du service		: Obtenir la liste des fichier ouverts dans le plan de classification
But 					: Obtenir la liste des fichier ouverts dans le plan de classification
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@vcChemin					Filtre sur le dossier dont on veut obtenir la liste des document ouverts 
							

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

		
Exemple utilisation:																					
	- Obtenir la liste des fichiers pour un souscripteur
		EXEC psGENE_ObtenirListeFichierOuvert 
		EXEC psGENE_ObtenirListeFichierOuvert '802-100_SOUSCRIPTEUR'
			
TODO:
	
Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2011-07-20	Pierre-Luc Simard					Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirListeFichierOuvert]
	@vcChemin VARCHAR(255) = ''
AS
BEGIN
	DECLARE
		@vcCommande VARCHAR(250),
		@vcRepertoire VARCHAR(250)

	CREATE TABLE #tblTEMP_Resultat (
		id INT IDENTITY (1,1),
		line NVARCHAR(1000)
	)

	--SET @vcCommande = 'C:\Scripts\PsFile\psfile \\srvapp06 -u controleur -p PASSWORD'
	SET @vcCommande = 'C:\Scripts\PsFile\psfile \\srvapp06 -u svc_openfiles -p hn2ZfNM5aqOe9mOjqmpq'
	
	INSERT INTO #tblTEMP_Resultat (line) EXEC xp_cmdshell @vcCommande
 
	-- Retourner les valeurs
	SELECT DISTINCT
		vcFichier = REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)),
		vcUtilisateur = substring(U.line,13,LEN(U.line))
	--INTO TMP_FichiersOuverts
	FROM #tblTEMP_Resultat F
	JOIN #tblTEMP_Resultat U ON U.id = F.id + 1
	WHERE LEFT(F.line,1) = '['
		AND REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) <> ' \srvsvc'
		AND (@vcChemin = '' OR REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) LIKE '%' + @vcChemin + '%')
	ORDER BY REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) 
	
END

