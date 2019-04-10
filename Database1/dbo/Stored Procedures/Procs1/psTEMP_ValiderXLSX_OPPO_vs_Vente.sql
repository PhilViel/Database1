/****************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc.

Code du service	:		psTEMP_ValiderXLSX_OPPO_vs_Vente
Nom du service		:	psTEMP_ValiderXLSX_OPPO_vs_Vente
But 				:	Valider le contenu d'un fichier d'OPPO vs les ventes qui ont suivi
Facette			: TEMP

Paramètres d’entrée	:   Paramètre					Description
				    --------------------------	-----------------------------------------------------------------

Exemple d’appel	:	
    exec psTEMP_ValiderXLSX_OPPO_vs_Vente @EnDateDu = '2017-07-01'
	
	drop proc psTEMP_ValiderXLSX_OPPO_vs_Vente

--create table tblTEMP_ImporterXLSX_Dans_Un_RepCharge (vcUserID varchar(255))

Paramètres de sortie:	

Historique des modifications:
	Date			Programmeur					Description
	------------	-------------------------	-----------------------------------------------------
	2018-03-13		Donald Huppé				Création du service		
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psTEMP_ValiderXLSX_OPPO_vs_Vente]
(
	@EnDateDu datetime
)
AS
BEGIN

	Declare 
		--@PeutFaireImportation int = 1
		@cMessage varchar (500) = 'Opportunités provenant de ce fichier : \\filesprod\PlanDeClassification\000_PANIER_DE_CLASSEMENT\000-100_TOUS\tab_OPPO.xlsx'

		--print @cMessage

	if exists (select name from sysobjects where name = 'tblTEMP_ValiderXLSX_OPPO_vs_Vente')
		begin	
		drop table tblTEMP_ValiderXLSX_OPPO_vs_Vente
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

        SET @vcChemin = '000_PANIER_DE_CLASSEMENT\000-100_TOUS\tab_OPPO.xlsx'

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
                SET @cMessage = 'Erreur : Demandez d''abord à l''utilisateur --> ' + upper(@vcUtilisateur) +  ' <-- de fermer le fichier : ' + @vcChemin + ' (et attendre environ 10 secondes)'
                --set @PeutFaireImportation = 0
				select 
					compteur = NULL, 
					nom = NULL, 
					QteSousc = NULL, 
					QteNouvelleConv = NULL, 
					QteAjoutunite = NULL, 
					LeMessage = @cMessage
				RETURN
            END	



	SET @Source =	'Excel 12.0 Xml;Database=' + @Directory + '\' + 'tab_OPPO.xlsx'
	SET @mystring = 
					'SELECT A.compteur, A.Prenom	,A.Nom	,A.Adresse	,A.Ville	,A.CodePostal	,A.Province	,A.TelMaison	,A.TelCel	,A.TelBur	,A.TelAutre

					 into tblTEMP_ValiderXLSX_OPPO_vs_Vente
					FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'', ''' + @Source + ''',
							''SELECT *
							FROM [Feuil1$]'') AS a'
	EXEC (@MyString)



	select g.compteur,g.nom,QteSousc = count(DISTINCT ha.SubscriberID), QteNouvelleConv = sum(isnull(ha.QteNouvelleConv,0)), QteAjoutunite = sum(isnull(QteAjoutUnite,0))
		,LeMessage = @cMessage
	from tblTEMP_ValiderXLSX_OPPO_vs_Vente g
	left join (
		select DISTINCT s.SubscriberID, qc.QteNouvelleConv, ajout.QteAjoutUnite, hs.LastName, hs.FirstName, a.vcCodePostal, TelMaison = tMais.vcTelephone, TelBur = tbur.vcTelephone, TelCel = tcel.vcTelephone
		from Un_Subscriber s
		join Mo_Human hs on s.SubscriberID = hs.HumanID
		join tblGENE_Adresse a on a.iID_Source = hs.HumanID
		left join tblGENE_Telephone tMais on tMais.iID_Source = hs.HumanID and GETDATE() BETWEEN tMais.dtDate_Debut and isnull(tMais.dtDate_Fin,'9999-12-31') and tMais.iID_Type = 1
		left join tblGENE_Telephone tBur on tBur.iID_Source = hs.HumanID and GETDATE() BETWEEN tBur.dtDate_Debut and isnull(tBur.dtDate_Fin,'9999-12-31') and tBur.iID_Type = 4
		left join tblGENE_Telephone tCel on tCel.iID_Source = hs.HumanID and GETDATE() BETWEEN tCel.dtDate_Debut and isnull(tCel.dtDate_Fin,'9999-12-31') and tCel.iID_Type = 2
		left join (
			select c1.SubscriberID, QteNouvelleConv = COUNT(*)
			from (
				select c.ConventionID
				from Un_Convention c
				join Un_Unit u on c.ConventionID = u.ConventionID
				group by c.ConventionID
				HAVING min(u.SignatureDate)>= @EnDateDu
				)d
			join Un_Convention c1 on d.ConventionID = c1.ConventionID
			GROUP by c1.SubscriberID
			)qc on qc.SubscriberID = s.SubscriberID

		left join (
			select c.SubscriberID, QteAjoutUnite = count(DISTINCT u.UnitID)
			from Un_Convention c
			join Un_Unit u on c.ConventionID = u.ConventionID
			left JOIN (
				select ConventionID,MinUnitID = min(UnitID) from Un_Unit GROUP by ConventionID
					)mu on u.UnitID = mu.MinUnitID
			WHERE 
				mu.MinUnitID is null 
				AND u.SignatureDate >= @EnDateDu
			group by c.SubscriberID
			)ajout on ajout.SubscriberID = s.SubscriberID

	) ha on (
			(g.CodePostal = ha.vcCodePostal)
			and (g.TelMaison = ha.TelMaison or g.TelBur = ha.TelBur or g.TelCel = ha.TelCel)
			)
	where g.compteur is not null
	group by  g.compteur,g.nom
	order by g.compteur



	end	


