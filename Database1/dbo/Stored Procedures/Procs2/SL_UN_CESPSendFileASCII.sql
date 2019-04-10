/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPSendFileASCII
Description         :	Retourne les données nécessaires pour le fichier ASCII 	d'envoi au PCEE.
Valeurs de retours  :	@Return_Value :
									>0  :	Tout à fonctionné
		                  	<=0 :	Erreur SQL
Note                :	ADX0000811	IA	2006-04-13	Bruno Lapointe		Création
                    :                   2008-10-16  Fatiha Araar		Modification pour l'ajout des enregistrements 511
										2009-02-13	Patrick Robitaille	Correction au niveau des 511 car le numéro de transaction inscrit 
																		était celui de la 400 originale au lieu de celui commençant par PCG.
										2009-03-03	Patrick Robitaille	Fixer à 15 caractères le vcTransID des cotisations des 511.
										2015-02-13	Donald Huppé		Pour les 200, si le pays est autre que CAN, USA, on met OTH. On fait ça ici car on ne veut pas ajouter OTH dans mo_country
										2016-01-21  Steeve Picard		Optimisation du compteur @iNbRecord
                                        2016-09-06  Pierre-Luc Simard   Ajout du tri
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPSendFileASCII] (
	@iCESPSendFileID INTEGER -- ID du fichier d'envoi au PCEE.
) AS
BEGIN
	DECLARE
		@vcPrefix VARCHAR(75),
		@iNbRecord INTEGER

	SELECT 
		@vcPrefix = SUBSTRING(vcCESPSendFile,2,25)
	FROM Un_CESPSendFile
	WHERE iCESPSendFileID = @iCESPSendFileID
	
    CREATE TABLE #tCESPFile (
		vcCESPTransac VARCHAR(500) )

	INSERT INTO #tCESPFile
		-- Enregistrement 001
		SELECT 
			vcCESPTransac = 
				-- Type d'enregistrement 9(3) 1-3
				'001'+
				-- Préfix, comprend le NE de l'expéditeur, la date d'envoi et le numéro de fichier X(25) 4-28
				@vcPrefix+
				-- Version de données 9(2)V9 29-31
				'040'+
				-- Remplissage X(469) 32-500
				SPACE(469)
		---------
		UNION ALL
		--------- 
		-- Enregistrement 100
		SELECT 
			vcCESPTransac =
				-- Type d'enregistrement 9(3) 1-3
				'100'+
				-- Date de la transaction 9(8) 4-11
				CAST(YEAR(dtTransaction) AS CHAR(4))+ 
				SUBSTRING('0'+CAST(MONTH(dtTransaction) AS VARCHAR),LEN('0'+CAST(MONTH(dtTransaction) AS VARCHAR))-1,2)+ 
				SUBSTRING('0'+CAST(DAY(dtTransaction) AS VARCHAR),LEN('0'+CAST(DAY(dtTransaction) AS VARCHAR))-1,2)+ 
				-- ID de transaction du promoteur X(15) 12-26
				CAST(vcTransID AS CHAR(15))+ 
				-- NE du promoteur X(15) 27-41
				'0000105444723RC'+ 
				-- Type de transaction 9(2) 42-43
				'01'+ 
				-- ID du régime type 9(10) 44-53
				SUBSTRING('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR),LEN('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR))-9,10)+ 
				-- ID du contrat X(15) 54-68
				CAST(ConventionNo AS CHAR(15))+
				-- Positions non utilisés X(34) 69-102
				SPACE(34)+
				-- Individuel / frères ou soeurs seulement 9(1) 103-103
				'1'+
				-- Remplissage X(397) 104-500
				SPACE(397)
		FROM Un_CESP100
		WHERE iCESPSendFileID = @iCESPSendFileID
		---------
		UNION ALL
		---------
		-- Enregistrement 200
		SELECT 
			vcCESPTransac =
				-- Type d'enregistrement 9(3) 1-3
				'200'+
				-- Date de la transaction 9(8) 4-11
				CAST(YEAR(dtTransaction) AS CHAR(4))+ 
				SUBSTRING('0'+CAST(MONTH(dtTransaction) AS VARCHAR),LEN('0'+CAST(MONTH(dtTransaction) AS VARCHAR))-1,2)+ 
				SUBSTRING('0'+CAST(DAY(dtTransaction) AS VARCHAR),LEN('0'+CAST(DAY(dtTransaction) AS VARCHAR))-1,2)+ 
				-- ID de transaction du promoteur X(15) 12-26
				CAST(vcTransID AS CHAR(15))+ 
				-- NE du promoteur X(15) 27-41
				'0000105444723RC'+
				-- Type de transaction 9(2) 42-43
				'0'+CAST(tiType AS CHAR(1))+
				-- ID du régime type 9(10) 44-53
				SUBSTRING('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR),LEN('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR))-9,10)+ 
				-- ID du contrat X(15) 54-68
				CAST(ConventionNo AS CHAR(15))+
				-- NAS 9(9) 69-77
				CAST(vcSINorEN AS CHAR(9))+
				-- Prénom X(20) 78-97 et nom X(20) 98-117
				CASE 
					WHEN bIsCompany = 0 THEN CAST(vcFirstName AS CHAR(20))+CAST(vcLastName AS CHAR(20))
				ELSE CAST(vcLastName AS CHAR(40))
				END+
				-- Date de naissance 9(8) 118-125
				CASE 
					WHEN dtBirthdate IS NULL THEN '        '
				ELSE
					CAST(YEAR(dtBirthdate) AS CHAR(4))+ 
					SUBSTRING('0'+CAST(MONTH(dtBirthdate) AS VARCHAR),LEN('0'+CAST(MONTH(dtBirthdate) AS VARCHAR))-1,2)+ 
					SUBSTRING('0'+CAST(DAY(dtBirthdate) AS VARCHAR),LEN('0'+CAST(DAY(dtBirthdate) AS VARCHAR))-1,2)
				END+
				-- Sexe 9(1) 126-126
				CASE 
					WHEN cSex IS NULL THEN ' '
					WHEN bIsCompany = 1 THEN ' '
					WHEN cSex = 'F' THEN '1'
					WHEN cSex = 'M' THEN '2'
				ELSE ' '
				END+
				-- Type de lien de parenté 9(1) 127-127
				CASE
					WHEN tiType = 4 THEN CAST(ISNULL(tiRelationshipTypeID,0) AS CHAR(1))
				ELSE '0'
				END+
				-- Ligne d'adresse 1 X(40) 128-167
				CAST(vcAddress1 AS CHAR(40))+
				-- Ligne d'adresse 2 X(40) 168-207
				CAST(vcAddress2 AS CHAR(40))+
				-- Ligne d'adresse 3 X(40) 208-247
				CAST(vcAddress3 AS CHAR(40))+
				-- Ville X(30) 248-277
				CAST(vcCity AS CHAR(30))+
				-- Province A(2) 278-279
				ISNULL(vcStateCode,'  ')+
				-- Pays A(3) 280-282
				CASE WHEN CountryID IN ('CAN','USA') THEN SUBSTRING(UPPER(CountryID),1,3) ELSE 'OTH' END + -- 2015-02-13 on fait ça ici car on ne veut pas ajouter OTH dans mo_country
				--SUBSTRING(UPPER(CountryID),1,3)+
				-- Code postal X(10) 283-292
				CAST(REPLACE(ISNULL(vcZipCode,''),' ','') AS CHAR(10))+
				-- Espace vide X(117) 293-409
				SPACE(117)+
				-- Langue 9(1) 410-410
				CASE
					WHEN cLang = 'ENU' THEN '1'
				ELSE '2' 
				END+
				-- Nom du parent ayant la garde X(30) 411-440
				CAST(ISNULL(vcTutorName,'') AS CHAR(30))+
				-- Remplissage X(60) 441-500
				SPACE(60)
		FROM Un_CESP200
		WHERE iCESPSendFileID = @iCESPSendFileID
		---------
		UNION ALL
		---------
		-- Enregistrement 400
		SELECT 
			vcCESPTransac =
				-- Type d'enregistrement 9(3) 1-3
				'400'+
				-- Date de la transaction 9(8) 4-11
				CAST(YEAR(C4.dtTransaction) AS CHAR(4))+ 
				SUBSTRING('0'+CAST(MONTH(C4.dtTransaction) AS VARCHAR),LEN('0'+CAST(MONTH(C4.dtTransaction) AS VARCHAR))-1,2)+ 
				SUBSTRING('0'+CAST(DAY(C4.dtTransaction) AS VARCHAR),LEN('0'+CAST(DAY(C4.dtTransaction) AS VARCHAR))-1,2)+ 
				-- ID de transaction du promoteur X(15) 12-26
				CAST(C4.vcTransID AS CHAR(15))+ 
				-- NE du promoteur X(15) 27-41
				'0000105444723RC'+
				-- Type de transaction 9(2) 42-43
				CAST(C4.tiCESP400TypeID AS CHAR(2))+
				-- ID du régime type 9(10) 44-53
				SUBSTRING('0000000000'+CAST(C4.iPlanGovRegNumber AS VARCHAR),LEN('0000000000'+CAST(C4.iPlanGovRegNumber AS VARCHAR))-9,10)+ 
				-- ID du contrat X(15) 54-68
				CAST(C4.ConventionNo AS CHAR(15))+
				-- NAS du souscripteur 9(9) 69-77
				CAST(C4.vcSubscriberSINorEN AS CHAR(9))+
				-- NAS du bénéficiaire 9(9) 78-86
				CAST(C4.vcBeneficiarySIN AS CHAR(9))+
				-- Montant de cotisation 9(7)V99 87-95
				CASE 
					WHEN C4.tiCESP400TypeID = 11 THEN dbo.FN_UN_SCEEMoneyToString(C4.fCotisation)
				ELSE '000000000'
				END+
				-- Subvention demandée X(1) 96-96
				CAST(C4.bCESPDemand AS CHAR(1))+
				-- Espace vide X(4) 97-100
				SPACE(4)+
				-- Date de début de l'année scolaire 9(8) 101-108
				CASE
					WHEN C4.tiCESP400TypeID IN (13,14) THEN 
						CAST(YEAR(C4.dtStudyStart) AS CHAR(4))+ 
						SUBSTRING('0'+CAST(MONTH(C4.dtStudyStart) AS VARCHAR),LEN('0'+CAST(MONTH(C4.dtStudyStart) AS VARCHAR))-1,2)+ 
						SUBSTRING('0'+CAST(DAY(C4.dtStudyStart) AS VARCHAR),LEN('0'+CAST(DAY(C4.dtStudyStart) AS VARCHAR))-1,2)
				ELSE '00000000'
				END+
				-- Durée de l'année scolaire 9(3) 109-111
				CASE 
					WHEN C4.tiCESP400TypeID IN (13,14) THEN SUBSTRING('000'+CAST(C4.tiStudyYearWeek AS VARCHAR),LEN('000'+CAST(C4.tiStudyYearWeek AS VARCHAR))-2,3)
				ELSE '000'
				END+
				-- Espace vide X(9) 112-120
				SPACE(9)+
				-- Indicateur d'annulation 9(1) 121-121
				CASE 
					WHEN C4.iReversedCESP400ID IS NULL THEN '1'
				ELSE '2'
				END+
				-- ID de la transaction originale du promoteur X(15) 122-136
				ISNULL(CAST(R4.vcTransID AS CHAR(15)),SPACE(15))+
				-- NE du promoteur original X(15) 137-151
				CASE 
					WHEN C4.iReversedCESP400ID IS NULL THEN SPACE(15)
				ELSE '0000105444723RC'
				END+
				-- Montant de la subvention 9(7)V99 152-160
				dbo.FN_UN_SCEEMoneyToString(C4.fCESG)+
				-- Montant de PAE imputable à la subvention 9(7)V99 161-169
				dbo.FN_UN_SCEEMoneyToString(C4.fEAPCESG)+
				-- Montant du PAE 9(7)V99 170-178
				dbo.FN_UN_SCEEMoneyToString(C4.fEAP)+
				-- Montant pour EPS 9(7)V99 179-187
				dbo.FN_UN_SCEEMoneyToString(C4.fPSECotisation)+
				-- ID du régime type 9(10) 188-197
				CASE 
					WHEN C4.tiCESP400TypeID IN (19,23) THEN SUBSTRING('0000000000'+CAST(ISNULL(C4.iOtherPlanGovRegNumber,0) AS VARCHAR),LEN('0000000000'+CAST(ISNULL(C4.iOtherPlanGovRegNumber,0) AS VARCHAR))-9,10)
				ELSE '0000000000'
				END+
				-- ID de l'autre contrat X(15) 198-212
				CASE 
					WHEN C4.tiCESP400TypeID IN (19,23) THEN CAST(ISNULL(C4.vcOtherConventionNo,'') AS CHAR(15))
				ELSE SPACE(15)
				END+
				-- Raison du remboursement 9(2) 213-214
				CASE 
					WHEN C4.tiCESP400TypeID = 21 THEN SUBSTRING('00'+CAST(ISNULL(C4.tiCESP400WithdrawReasonID,0) AS VARCHAR),LEN('00'+CAST(ISNULL(C4.tiCESP400WithdrawReasonID,0) AS VARCHAR))-1,2)
				ELSE '00'
				END+
				-- Durée du programme d'EPS 9(1) 215-215
				CASE 
					WHEN C4.tiCESP400TypeID IN (13,14) THEN CAST(ISNULL(C4.tiProgramLength,0) AS CHAR(1))
				ELSE '0'
				END+
				-- Type d'études postsecondaires 9(2) 216-217
				CASE 
					WHEN C4.tiCESP400TypeID IN (13,14) THEN ISNULL(C4.cCollegeTypeID,'00')
				ELSE '00'
				END+
				-- Code postal de l'établissement d'enseignement X(10) 218-227
				CASE 
					WHEN C4.tiCESP400TypeID IN (13,14) THEN CAST(ISNULL(C4.vcCollegeCode,'') AS CHAR(10))
				ELSE SPACE(10)
				END+
				-- Année du programme d'EPS 9(1) 228-228
				CASE 
					WHEN C4.tiCESP400TypeID IN (13,14) AND ISNULL(C4.siProgramYear,0) >= 9 THEN '9'
					WHEN C4.tiCESP400TypeID IN (13,14) THEN CAST(ISNULL(C4.siProgramYear,0) AS CHAR(1))
				ELSE '0'
				END+
				-- Principal responsable X(15) 229-243
				CAST(ISNULL(C4.vcPCGSINorEN,'') AS CHAR(15))+
				-- Prénom du principal responsable X(20) 244-263 et nom X(20) 264-283
				CASE
					WHEN ISNULL(C4.tiPCGType,0) = 1 THEN CAST(ISNULL(C4.vcPCGFirstName,'') AS CHAR(20))+CAST(ISNULL(C4.vcPCGLastName,'') AS CHAR(20))
				ELSE CAST(ISNULL(C4.vcPCGLastName,'') AS CHAR(40))
				END+
				-- Type de principal responsable 9(1) 284-284
				CAST(ISNULL(C4.tiPCGType,0) AS CHAR(1))+
				-- Montant du BEC 9(7)V99 285-293
				dbo.FN_UN_SCEEMoneyToString(C4.fCLB)+
				-- Montant du PAE imputable au BEC 9(7)V99 294-302
				dbo.FN_UN_SCEEMoneyToString(C4.fEAPCLB)+
				-- Montant de la subvention provinciale 9(7)V99 303-311
				dbo.FN_UN_SCEEMoneyToString(C4.fPG)+
				-- Montant du PAE imputable à la subvention provinciale 9(7)V99 312-320
				dbo.FN_UN_SCEEMoneyToString(C4.fEAPPG)+
				-- Province de la subvention provinciale A(2) 321-322
				CAST(ISNULL(C4.vcPGProv,'') AS CHAR(2))+
				-- Remplissage X(178) 323-500
				SPACE(178)
		FROM Un_CESP400 C4
		LEFT JOIN Un_CESP400 R4 ON R4.iCESP400ID = C4.iReversedCESP400ID
		WHERE C4.iCESPSendFileID = @iCESPSendFileID
		---------
		UNION ALL
		---------
		-- Enregistrement 700
		SELECT 
			vcCESPTransac =
				-- Type d'enregistrement 9(3) 1-3
				'700'+
				-- Date de la transaction 9(8) 4-11
				CAST(YEAR(S.dtCESPSendFile) AS CHAR(4))+ 
				SUBSTRING('0'+CAST(MONTH(S.dtCESPSendFile) AS VARCHAR),LEN('0'+CAST(MONTH(S.dtCESPSendFile) AS VARCHAR))-1,2)+ 
				SUBSTRING('0'+CAST(DAY(S.dtCESPSendFile) AS VARCHAR),LEN('0'+CAST(DAY(S.dtCESPSendFile) AS VARCHAR))-1,2)+ 
				-- NE du promoteur X(15) 12-26
				'0000105444723RC'+ 
				-- ID du régime type 9(10) 27-36
				SUBSTRING('0000000000'+CAST(C7.iPlanGovRegNumber AS VARCHAR),LEN('0000000000'+CAST(C7.iPlanGovRegNumber AS VARCHAR))-9,10)+ 
				-- ID du contrat X(15) 37-51
				CAST(C7.ConventionNo AS CHAR(15))+
				-- Actif total des REEE 9(7)V99 52-60
				dbo.FN_UN_SCEEMoneyToString(C7.fMarketValue)+
				-- Remplissage X(440) 61-500
				SPACE(440)
		FROM Un_CESP700 C7
		JOIN Un_CESPSendFile S ON S.iCESPSendFileID = C7.iCESPSendFileID
		WHERE C7.iCESPSendFileID = @iCESPSendFileID
		---------
		UNION ALL
		---------
	-- Enregistrement 511
     SELECT 
            vcCESPTransac =
            --Type d'enregistrement 9(3) 1-3
            '511'+
            --Date de la transaction 9(8) 4-11
            CAST(YEAR(dtTransaction) AS CHAR(4))+ 
			SUBSTRING('0'+CAST(MONTH(dtTransaction) AS VARCHAR),LEN('0'+CAST(MONTH(dtTransaction) AS VARCHAR))-1,2)+ 
			SUBSTRING('0'+CAST(DAY(dtTransaction) AS VARCHAR),LEN('0'+CAST(DAY(dtTransaction) AS VARCHAR))-1,2)+ 
            --ID de transaction du promoteur X(15) 12-26
            CAST(vcTransID AS CHAR(15))+
            --NE du promoteur X(15) 27-41
             '0000105444723RC'+
			--Type de transaction 9(2) 42-43
            '12'+
            --ID du régime type 9(10) 44-53
            SUBSTRING('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR),LEN('0000000000'+CAST(iPlanGovRegNumber AS VARCHAR))-9,10)+ 
            --ID du Contrat X(15) 54-68
            CAST(ConventionNo AS CHAR(15))+
            --ID de transaction de cotisation du promoteur X(15) 69-83
            CAST(vcOriginalTransID AS CHAR(15))+
            --NE du promoteur de la cotisation X(15) 84-98
              '0000105444723RC'+
            --Principal responsable X(15) 99-113
            CAST(vcPCGSINorEN AS CHAR(15))+
		    -- Prénom du principal responsable X(20) 114-133 et nom X(20) 134-153
			CASE
				WHEN ISNULL(tiPCGType,0) = 1 THEN CAST(ISNULL(vcPCGFirstName,'') AS CHAR(20))+CAST(ISNULL(vcPCGLastName,'') AS CHAR(20))
				ELSE CAST(ISNULL(vcPCGLastName,'') AS CHAR(40))
			END+
		   -- Type de principal responsable 9(1) 154
			CAST(tiPCGType AS CHAR(1))
		 FROM Un_CESP511 
		WHERE iCESPSendFileID = @iCESPSendFileID

     SELECT @iNbRecord = Count(*) + 1 FROM #tCESPFile

	INSERT INTO #tCESPFile
		-- Enregistrement 999
		SELECT 
			vcCESPTransac = 
				'999'+
				@vcPrefix+
				-- Compte des enregistrements 9(9) 29-37
				SUBSTRING('000000000'+CAST(@iNbRecord AS VARCHAR),LEN('000000000'+CAST(@iNbRecord AS VARCHAR))-8,9)+
				-- Remplissage X(463) 38-500
				SPACE(463)

        ----------------------------------------	
    SELECT 
		vcCESPTransac1 = SUBSTRING(vcCESPTransac, 1, 250),
		vcCESPTransac2 = SUBSTRING(vcCESPTransac, 251, 250)
	FROM #tCESPFile
    ORDER BY 
        LEFT(vcCESPTransac, 3),
        SUBSTRING(vcCESPTransac, 15, 12)
END
