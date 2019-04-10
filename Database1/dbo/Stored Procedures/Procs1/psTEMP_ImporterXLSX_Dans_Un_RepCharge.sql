/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service	:		psTEMP_ImporterXLSX_Dans_Un_RepCharge
Nom du service		:	psTEMP_ImporterXLSX_Dans_Un_RepCharge
But 				:	Importer des ajustement et retenu à partir d'un fichier Excel
Facette			: TEMP

Paramètres d’entrée	:   Paramètre					Description
				    --------------------------	-----------------------------------------------------------------

Exemple d’appel	:	
    exec psTEMP_ImporterXLSX_Dans_Un_RepCharge @vcUserID =  'dhuppe', @Importer = 0
	exec psTEMP_ImporterXLSX_Dans_Un_RepCharge @vcUserID =  'dhuppe', @Importer = 1

--create table tblTEMP_ImporterXLSX_Dans_Un_RepCharge (vcUserID varchar(255))

Paramètres de sortie:	

Historique des modifications:
	Date			Programmeur					Description
	------------	-------------------------	-----------------------------------------------------
	2017-03-07		Donald Huppé				Création du service		
	2017-03-20		Donald Huppé				Valider que le fichier n'est pas ouvert.
	2017-11-10		Donald Huppé				Ajout de glherault
	2018-01-25		Donald Huppé				Ajout de jchicoine
	2018-12-14		Donald Huppé				correction du message pour RepCodeInconnu et RepChargeTypeIDInconnu
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ImporterXLSX_Dans_Un_RepCharge] 
(
	@vcUserID varchar(255),
	@Importer int = 0
)
AS
BEGIN

	Declare 
		@PeutFaireImportation int = 1
		,@cMessage varchar (500) = ''


	if exists (select name from sysobjects where name = 'tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA')
		begin	
		drop table tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA
		end




	DECLARE
		@Directory VARCHAR(2000),
		@MyString VARCHAR(2000),
		@Source VARCHAR(2000)


	set @Directory = '\\filesprod\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS'


		-- Vérifier si le fichier est déjà ouvert
        DECLARE
            @vcCommande VARCHAR(250) ,
            @vcChemin VARCHAR(250) ,
            @vcUtilisateur VARCHAR(50)

        SET @vcChemin = '000_PANIER_DE_CLASSEMENT\000-100_TOUS\tab_importation_RepCharge.xlsx'

        CREATE TABLE #tblTEMP_Resultat (
            id INT IDENTITY(1, 1) ,
            line NVARCHAR(1000))

        SET @vcCommande = 'C:\Scripts\PsFile\psfile \\srvapp06 -u svc_openfiles -p hn2ZfNM5aqOe9mOjqmpq'
	
        INSERT  INTO #tblTEMP_Resultat
                (line)
                EXEC xp_cmdshell @vcCommande
 
		-- Retourner les valeurs
        SELECT TOP 1
			@vcUtilisateur = SUBSTRING(U.line, 13, LEN(U.line))
        FROM #tblTEMP_Resultat F
        JOIN #tblTEMP_Resultat U ON U.id = F.id + 1
        WHERE LEFT(F.line, 1) = '['
            AND REVERSE(LEFT(REVERSE(F.line), CHARINDEX(']', REVERSE(F.line)) - 1)) <> ' \srvsvc'
            AND (@vcChemin = ''
                 OR REVERSE(LEFT(REVERSE(F.line), CHARINDEX(']', REVERSE(F.line)) - 1)) LIKE '%' + @vcChemin + '%')
        	
        DROP TABLE #tblTEMP_Resultat

        IF @vcUtilisateur IS NOT NULL AND ISNULL(@vcUtilisateur, '') NOT LIKE '%service%'
            BEGIN
                SET @cMessage = 'Erreur : Demandez d''abord à l''utilisateur --> ' + upper(@vcUtilisateur) +  ' <-- de fermer le fichier : ' + @vcChemin
                set @PeutFaireImportation = 0
				select 
					RepCode = NULL, 
					RepChargeTypeID = NULL,	
					TypeDescription = NULL,	
					Montant = NULL,	
					LaDescription = NULL,
					RepCodeInconnu = NULL,
					RepChargeTypeIDInconnu = NULL,
					DejaImporte = NULL,
					ImportationReussie = NULL,
					LeMessage = @cMessage
				RETURN
            END	



	SET @Source =	'Excel 12.0 Xml;Database=' + @Directory + '\' + 'tab_importation_RepCharge.xlsx'
	SET @mystring = 
					'SELECT 
						RepCode = LTRIM(RTRIM(a.RepCode)), 
						RepChargeTypeID = LTRIM(RTRIM(a.RepChargeTypeID)),	
						Montant = cast(a.Montant as money),	
						--LeType = LTRIM(RTRIM(a.Type)),	
						LaDescription = LTRIM(RTRIM(a.Description))

					 into tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA --tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA
					FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''' + @Source + ''',
							''SELECT *
							FROM [Feuil1$]'') AS a'
	EXEC (@MyString)

	DELETE from tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA WHERE repCode is null


	

	if @vcUserID not like '%girard%' and @vcUserID not like '%hupp%' and @vcUserID not like '%tessier%' and @vcUserID not like '%plsimard%' and @vcUserID not like '%glherault%'  and @vcUserID not like '%jchicoine%'
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Usager non autorisé : ' + @vcUserID
		set @PeutFaireImportation = 0
		--goto abort
		end		



	IF @Importer = 0
		begin
		delete from tblTEMP_ImporterXLSX_Dans_Un_RepCharge 
		insert into tblTEMP_ImporterXLSX_Dans_Un_RepCharge VALUES (@vcUserID)
		end


	if @Importer = 1 and not exists(SELECT 1 from tblTEMP_ImporterXLSX_Dans_Un_RepCharge where vcUserID = @vcUserID)
		begin
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end +  'Attention. Demandez d''abord le rapport sans demander l ''imporation !'
		set @PeutFaireImportation = 0
		end

	
	select 
		a.* 
		, TypeDescription = RCT.RepChargeTypeDesc
		, RepCodeInconnu = CASE WHEN r.RepCode is NULL then 1 else 0 end
		, RepChargeTypeIDInconnu = CASE WHEN  rct.RepChargeTypeID is NULL then 1 else 0 end
		, DejaImporte = CASE WHEN rc.RepChargeID is not null then 1 else 0 end
		, LeMessage = ''

	INTO #tmpresult
	from tblTEMP_ImporterXLSX_Dans_Un_RepChargeDATA  a
	LEFT JOIN Un_Rep R on r.RepCode = a.RepCode
	LEFT JOIN Un_RepChargeType RCT on rct.RepChargeTypeID = a.RepChargeTypeID
	LEFT JOIN Un_RepCharge Rc on 
			RC.RepID = r.RepID 
		AND rc.RepChargeTypeID =  LTRIM(RTRIM(a.RepChargeTypeID))
		AND rc.RepChargeDesc = ltrim(rtrim(a.LaDescription))
		AND rc.RepChargeAmount = CAST(a.Montant as money)
		AND isnull(rc.RepTreatmentID,0) = 0

	if EXISTS (select 1 from #tmpresult where RepCodeInconnu = 1)
		BEGIN
		SET @PeutFaireImportation = 0
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Erreur : Code de rep inconnu. Vérifier valeur 1 dans la colonne --Rep Code Inconnu--'
		END


	if EXISTS (select 1 from #tmpresult where RepChargeTypeIDInconnu = 1)
		BEGIN
		SET @PeutFaireImportation = 0
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Erreur : RepChargeTypeID inconnu. Vérifier valeur 1 dans la colonne --Rep Charge Type ID Inconnu--'
		END


	if EXISTS (select 1 from #tmpresult where DejaImporte = 1)
		BEGIN
		SET @PeutFaireImportation = 0
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Erreur : Ce fichier a déjà été importé.'
		END



	IF @PeutFaireImportation = 1
		BEGIN
		set @cMessage = @cMessage + case WHEN len(ltrim(rtrim(@cMessage))) > 0 then char(10) ELSE '' end + 'Importation autorisée des ajustements et retenues suivantes. Validez le montant total.'
		END





	IF @Importer = 1 and @PeutFaireImportation = 1
		BEGIN
		INSERT INTO Un_RepCharge (
				RepID, -- ID du représentant.
				RepChargeTypeID, -- ID du type de charge.
				RepChargeDesc, -- Note indiquant la raison de l’ajustement ou de la retenu.
				RepChargeAmount, -- Montant de l’ajustement(+) ou de la retenu(-)
				RepTreatmentID, -- ID unique du traitement de commissions dans lequel l'ajustement ou la retenu a été traité. Null = pas encore traité.
				RepChargeDate ) 
		SELECT  
			r.RepID, 
			RepChargeTypeID = LTRIM(RTRIM(b.RepChargeTypeID)), 
			RepChargeDesc = LTRIM(RTRIM(LaDescription)),
			RepChargeAmount =b.Montant, 
			RepTreatmentID = NULL,
			RepChargeDate = CAST(GETDATE() AS DATE) --'2016-10-06 00:00:00'
		FROM #tmpresult b
		JOIN Un_Rep r ON b.repcode = r.RepCode


		Delete from tblTEMP_ImporterXLSX_Dans_Un_RepCharge where vcUserID = @vcUserID


		--select *
		--into aaatmpresult
		--FROM #tmpresult

		IF EXISTS (
				SELECT 
					1
				FROM #tmpresult a
				LEFT JOIN Un_Rep R on r.RepCode = a.RepCode
				LEFT JOIN Un_RepCharge Rc on 
						RC.RepID = r.RepID 
					AND rc.RepChargeTypeID =  LTRIM(RTRIM(a.RepChargeTypeID))
					AND rc.RepChargeDesc = ltrim(rtrim(a.LaDescription))
					AND rc.RepChargeAmount = CAST(a.Montant as money)
					AND isnull(rc.RepTreatmentID,0) = 0

				WHERE Rc.RepChargeID IS NULL
					
						)
			BEGIN
			SET @PeutFaireImportation = 0
			SET @cMessage = 'Erreur : importation non réussie.'
			END

			ELSE

			BEGIN
			SET @cMessage = 'Importation Réussie .'
			END


		
		END




	select 
		a.RepCode, 
		a.RepChargeTypeID,	
		TypeDescription,	
		Montant,	
		LaDescription,
		RepCodeInconnu,
		RepChargeTypeIDInconnu,
		DejaImporte,
		ImportationReussie = CASE WHEN rc.RepChargeID is not null AND @Importer = 1 and @PeutFaireImportation = 1 then 1 else 0 end,
		LeMessage = @cMessage
	from #tmpresult a
	LEFT JOIN Un_Rep R on r.RepCode = a.RepCode
	LEFT join Un_RepCharge Rc on 
			RC.RepID = r.RepID 
		and rc.RepChargeTypeID = a.RepChargeTypeID
		and rc.RepChargeDesc = a.LaDescription
		and rc.RepChargeAmount = CAST(a.Montant as money)
		and isnull(rc.RepTreatmentID,0) = 0


	end	



/*
-- Résultat
SELECT hr.FirstName,hr.LastName, r.RepCode, rc.*
from Un_RepCharge rc
join Un_Rep r ON rc.RepID = r.RepID
join Mo_Human hr on r.RepID = hr.HumanID
where rc.RepChargeDate = CAST(GETDATE() AS DATE)
ORDER BY RepChargeTypeID,rc.RepChargeAmount

*/