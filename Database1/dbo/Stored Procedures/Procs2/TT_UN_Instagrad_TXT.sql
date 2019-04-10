/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                :		TT_UN_Instagrad_TXT
Description       :	Procédure créant les fichiers .csv pour Instagrad (Liste des conventions, Liste des représentants)
Note                :		2014-03-03	Pierre-Luc Simard	Création
							2014-03-13	Donald Huppé		glpi 11174 : ajout de rep. et refaire la clause where avec les repcode au lieu des noms de rep
							2014-05-27	Donald Huppé		Demande de Marie-Pier Gignac : retirer les rep : 6715,6102,6417,7288
							2014-11-17	Donald Huppé		Élargir la liste à tous les souscripteurs de tous les représentants (demande de Jenny)
							2015-01-26	Donald Huppé		glpi 13275 : Ajouter pour le rep : tel travail et courriel professionel
							2018-09-25  Pierre-Luc Simard   Ce traitement n'est plus utilisé
                             
			EXEC TT_UN_Instagrad_TXT '\\srvapp06\dhuppe$\GLPI\ListeConvention.csv', '\\srvapp06\dhuppe$\GLPI\ListeRep.csv'
						
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_Instagrad_TXT] ( 
	@vcNomFichierConv varchar(100),
	@vcNomFichierRep varchar(100)) 
AS 
BEGIN
    DECLARE @str VARCHAR(1000) 
    DECLARE @DataBaseName VARCHAR(255) 
    
    SELECT @DataBaseName = DB_NAME()

	IF EXISTS (SELECT Name FROM SYSOBJECTS WHERE Name = 'TMP_Instagrad_Rep')
		DROP TABLE TMP_Instagrad_Rep

	IF EXISTS (SELECT Name FROM SYSOBJECTS WHERE Name = 'TMP_Instagrad_Conv')
		DROP TABLE TMP_Instagrad_Conv
		
	CREATE TABLE TMP_Instagrad_Rep (
		RepID INT,
		RepCode VARCHAR(75),
		Prenom_Representant VARCHAR(35),
		Nom_Representant VARCHAR(50),
		Telephone VARCHAR(27),
		Courriel VARCHAR(80))
	
	INSERT INTO dbo.TMP_Instagrad_Rep (
		RepID,
	    RepCode,
	    Prenom_Representant,
	    Nom_Representant,
		Telephone,
		Courriel)
	SELECT 
		R.RepID,
		R.RepCode,
		Prenom_Representant = HR.FirstName,
		Nom_Representant = HR.LastName,
		Telephone = max(ISNULL(tt.vcTelephone,'')), -- On prend le max juste pour s'assurer qu'on sort juste un tel travail actif, ce qui est théoriquement le cas
		Courriel = max(ISNULL(c.vcCourriel,''))-- On prend le max juste pour s'assurer qu'on sort juste un courriel proffessionel actif, ce qui est théoriquement le cas
	FROM Un_Rep R
	JOIN dbo.Mo_Human HR ON R.RepID = HR.HumanID
	LEFT JOIN tblGENE_Telephone tt on HR.HumanID = tt.iID_Source and getdate() BETWEEN tt.dtDate_Debut and isnull(tt.dtDate_Fin,'9999-12-31') and tt.iID_Type = 4
	LEFT JOIN tblGENE_Courriel c on c.iID_Source = hr.HumanID and GETDATE() BETWEEN c.dtDate_Debut and ISNULL(c.dtDate_Fin,'9999-12-31') and c.iID_Type = 2
	WHERE 
		isnull(R.BusinessEnd,'9999-12-31') > GETDATE()
		and isnull(r.BusinessStart,'9999-12-31') <= GETDATE() -- Le rep est actif
	group BY
		R.RepID,
		R.RepCode,
		HR.FirstName,
		HR.LastName
	/*
		AND R.RepCode in (
			'6800',--Asselin Sophie
			--'6715',--Béchard Natacha
			'7460',--Blackburn Caroline
			'7542',--Blais Carel
			'6569',--Boisvert Liette
			'6448',--Delorme Carole
			'6373',--Derome Michèle
			'70006',--Derome Myriam
			'7361',--Derome Myriam
			'7042',--Désormeaux Nataly
			'7190',--Dongmo André Roger
			'6943',--Duquette Karyne
			'6987',--Durivage Line
			'6848',--Foisy Brigitte
			'6779',--Fournier Lise
			'7693',--Fournier Lise
			'7794',--Fréchette Vénus
			'7106',--Fréchette Vénus
			'6767',--Gagnon Dorys
			'7379',--Gautreau Isabelle
			'7671',--Gilbert Chantal
			'6517',--Gilbert Pascal
			'7835',--Gingras Guillaume
			'6998',--Guillaume Danielle
			'7186',--Jobin Chantal
			'6936',--Lacroix Brigitte
			'7092',--Lafrance Thérèse
			'7005',--Lafrance Thérèse
			'6740',--Lagacé Charlante
			'7445',--Lanoie Mario
			'7233',--Larocque Stéphane
			'7136',--Lauzière Mélanie
			'6209',--Lecouteur Johanne
			'6863',--Leroux Jacques
			'6158',--Marchand Carole
			'7837',--Mercier Isabelle
			'7430',--Mhamdi Leila
			--'6102',--Paillé Manon
			'6614',--Plourde Rachelle
			'7433',--Poirier Manon
			'6907',--Poulin Nathalie
			'7550',--Prud'homme Josée
			'7462',--Racine Dany
			'7923',--Rancourt-Fortin Amélie
			--'6417',--Reeves Robert W.
			'7275',--Regnaud Karine
			'7526',--Simoneau Marcel
			'6141',--Social Siège
			'7050',--Vallée Sophie
			'7882'--Villemure Patrice
			--,'7288'--Zeiger Thibeault Rosita
		)
	*/
	ORDER BY R.RepID

	CREATE TABLE TMP_Instagrad_Conv (
		Id_beneficiaire INT,
		Nom_beneficiaire VARCHAR(50),
		Prenom_benefeciaire VARCHAR(35),
		DateNaissanceBenef VARCHAR(10),
		Id_souscripteur INT, 
		Nom_souscripteur VARCHAR(50), 
		Prenom_souscripteur VARCHAR(35),
		ConventionNo VARCHAR(15),
		RepID INT, 
		RepCode VARCHAR(75),
		Nom_Representant VARCHAR(50), 
		Prenom_Representant VARCHAR(35))
	
	INSERT INTO dbo.TMP_Instagrad_Conv (
		Id_beneficiaire,
		Nom_beneficiaire,
		Prenom_benefeciaire,
		DateNaissanceBenef,
		Id_souscripteur,
		Nom_souscripteur,
		Prenom_souscripteur,
		ConventionNo,
		RepID,
		RepCode,
		Nom_Representant,
		Prenom_Representant)
	SELECT 
		Id_beneficiaire = C.BeneficiaryID, 
		Nom_beneficiaire = HB.LastName,
		Prenom_benefeciaire = HB.FirstName,
		DateNaissanceBenef = LEFT(CONVERT(VARCHAR, HB.BirthDate, 120), 10),
		Id_souscripteur = C.SubscriberID, 
		Nom_souscripteur = HS.LastName, 
		Prenom_souscripteur = HS.FirstName,
		C.ConventionNo,
		REP.RepID, 
		REP.RepCode,
		Nom_Representant = HR.LastName, 
		Prenom_Representant = HR.FirstName
	FROM dbo.Un_Convention C
	JOIN (
		SELECT 
			Cs.conventionid ,
			ccs.startdate,
			cs.ConventionStateID
		FROM Un_ConventionConventionState cs
			join (
				select 
				conventionid,
				startdate = max(startDate)
				from un_conventionconventionstate
				--where LEFT(CONVERT(VARCHAR, startDate, 120), 10) <= '2011-10-31' -- Si je veux l'état à une date précise 
				group by conventionid
				) ccs on ccs.conventionid = cs.conventionid 
					and ccs.startdate = cs.startdate 
					and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
		) css on C.conventionid = css.conventionid
	JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
	JOIN dbo.Mo_Human hb ON c.BeneficiaryID = hb.HumanID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN Un_Rep REP ON REP.RepID = S.RepID
	JOIN dbo.Mo_Human HR ON rep.RepID = HR.HumanID
	LEFT JOIN TMP_Instagrad_Rep R ON R.RepID = S.RepID
	/*
	WHERE R.RepID IS NOT NULL 
		OR S.SubscriberID IN (-- Employés du Siège Social
			481096,
			549762,
			528396,
			686880,
			170149,
			380489,
			646611,
			408434,
			176127,
			525090,
			176794,
			177987,
			178033,
			578501,
			575993,
			607962,
			392932,
			667384,
			671847,
			601134,
			601813,
			431445,
			396631,
			601864,
			635452,
			654216,
			335659,
			601617,
			640905,
			586425,
			658479,
			159251)
	*/
	GROUP BY
		C.BeneficiaryID, 
		HB.LastName,
		HB.FirstName,
		HB.BirthDate,
		C.SubscriberID, 
		C.ConventionNo,
		HS.LastName, 
		HS.FirstName,
		REP.repid, 
		REP.repcode,
		HR.LastName,
		HR.FirstName
	ORDER BY 
		REP.RepID,
		C.SubscriberID

	--select * from TMP_Instagrad_Conv
	
	--return

	-- Le paramètre -C 65001 permet de générer le fichier en UTF-8
	--SET @str = 'Exec Master..xp_Cmdshell ''bcp "SELECT * FROM ' + @DataBaseName + '.dbo.TMP_Instagrad_Rep t ORDER BY t.Nom_Representant, Prenom_Representant " queryout "' + @vcNomFichierRep + '" -t"," -c -T ''' ---C 65001 ''' 
	--EXEC(@str) 
	--SET @str = 'Exec Master..xp_Cmdshell ''bcp "SELECT * FROM ' + @DataBaseName + '.dbo.TMP_Instagrad_Conv t ORDER BY t.RepID, t.Id_souscripteur " queryout "' + @vcNomFichierConv + '" -t"," -c -T ''' ---C 65001 ''' 
	--EXEC(@str) 
	
	exec SP_ExportTableToExcelWithColumns @DataBaseName, 'TMP_Instagrad_Rep', @vcNomFichierRep, 'RAW', 1
	exec SP_ExportTableToExcelWithColumns @DataBaseName, 'TMP_Instagrad_Conv', @vcNomFichierConv, 'RAW', 1
	
END

/*
-- Script pour permettre au serveur d'exécuter des commandes DOS
sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE
GO
*/