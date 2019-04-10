/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Nom du service		: psGENE_rapportListeFichiersOuverts
But 				: Rapport de la liste des fichiers ouverts dans le plan de classification
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@vcChemin					Filtre sur le dossier dont on veut obtenir la liste des document ouverts
						@vcLogin					Filtre sur l'utilisateur 


Exemple utilisation:	EXEC psGENE_rapportListeFichiersOuverts '', 'universitas\pgirard'
						EXEC psGENE_rapportListeFichiersOuverts '', 'universitas\mmartel'
						EXEC psGENE_rapportListeFichiersOuverts '802-100_SOUSCRIPTEUR', 'universitas\pgirard'
		
		
	
Historique des modifications:
		Date				Programmeur							Description									Référence
		------------		----------------------------------	-----------------------------------------	------------
		2013-10-23			Maxime Martel						Création du service	

*********************************************************************************************************************/
CREATE procedure [dbo].[psGENE_rapportListeFichiersOuverts] (
	@vcChemin VARCHAR(255) = '', 
	@vcLogin VARCHAR(255)
)
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
	INTO #TMP_FichiersOuverts
	FROM #tblTEMP_Resultat F
	JOIN #tblTEMP_Resultat U ON U.id = F.id + 1
	WHERE LEFT(F.line,1) = '['
		AND REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) <> ' \srvsvc'
		AND (@vcChemin = '' OR REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) LIKE '%' + @vcChemin + '%')
	ORDER BY REVERSE(LEFT(REVERSE(F.line),CHARINDEX(']',REVERSE(F.line))-1)) 
	
	if @vcLogin <> 'universitas\pgirard' and @vcLogin <> 'universitas\plsimard' and @vcLogin <> 'universitas\dloranger'
	and @vcLogin <> 'universitas\jpfortin'
		delete from #TMP_FichiersOuverts where vcFichier not like '%802-100%' and vcFichier not like '%802-400%'

	select * from #TMP_FichiersOuverts
END
