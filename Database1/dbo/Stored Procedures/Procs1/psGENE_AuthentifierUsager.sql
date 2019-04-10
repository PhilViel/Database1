/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_AuthentifierUsager
Nom du service		: Authentifie un usager
But 				: Permet de valider qu'un usager a accès ou non
Facette				: GENE
Référence			: Noyau-GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@iUserId					Identifiant de l'usager pour lequel on modifie la securite
						@vbMotPasse					Mot de passe usager
						@bCleConfirmationMD5		OPTIONEL - Permet de confirmer un compte usager (lien web)
Paramètres de sortie:	
		Return :	
					0					La sp s'est executee avec succes
					Code Erreur			Une erreur geree est survenue (Les dataset 1 et 2 ne sont pas retournes a ce moment)
					
		DataSet 1:	
					Resultat			Une valeur connue du code .Net = Authentification réussie (parametre GENE_AUTHENTIFICATION_VALEUR_RETOUR_SUCCES)
										Toute autre valeur = Echec d'authentification						
					MessageFrancais		Message a afficher a l'usager en francais
					MessageAnglais		Message a afficher a l'usager en anglais
					NoticeFrancais		Notice a afficher en Francais
					NoticeAnglais		Notice a afficher en Anglais
					Etat				Code d'état pour le service web 0,1,5
					
		DataSet 2:	
					Nom 		
					Prenom 	
					Adresse 			
					Ville 	
					Province 		
					CodePostal 	
					Pays 
					Courriel 
					ConsentementSouscripteur 
					ConsentementBeneficiaire
					TelMaison 
					TelBureau 
					NomRepresentant 
					PrenomRepresentant 
					TelRepresentant 
					CourrielRepresentant 

	- Il y a 3 types de messages:
			- Les messages d'erreur: On retourne que le numero de l'erreur au service
			- Les erreurs d'authentification : On retourne le message dans les 2 langues, afin de nous permettre de gerer eventuellement d'autres status sur le compte
			- Les messages de notifications (lors de l'Authentification): On retourne le message dans les 2 langues 
		
Exemple utilisation:																					

	- Confirmation et activation d'un nouveau compte (ou d'un nouveau courriel)
		EXEC psGENE_AuthentifierUsager 2, null, 0x02

	- Authentification normal d'un usager	
		EXEC psGENE_AuthentifierUsager 2, 0x1
	
Autres infos:
	Etat :
		0 - Compte créé mais non activé par le client										
		1 - Trop de tentatives (verrouillé temporairement après 3 tentatives)				
		2 - Trop de tentatives (verrouillé en permanence après 10 tentatives)				
		3 - Compte désactivé par l'administration (verrouillé)								
		4 - Inactif								
		5 - Actif
		6 - Inexistant
		
Question:
	
Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-08-10		Steve Gouin					Création du service						
		2011-02-09		Pierre-Luc Simard			Format des téléphones avec ()- et extension	
		2011-03-24		Pierre-Luc Simard			Ne pas afficher Siège Social et Head Office
		2011-04-27		Donald Huppé					Ajout du champ Type_humain
		2011-10-06		Eric Michaud					Ajout de NoticeFrancais et NoticeAnglais	    GLPI6182
		2012-01-11		Eric Michaud					Augmenter a 37 la longueur des champs télépnone	GLPI6182
		2014-02-20		Pierre-Luc Simard			Utilisation de bReleve_Papier au lieu de bConsentement

*********************************************************************************************************************
****** ATTENTION ****** Cette sp ne doit jamais être modifié directement, utiliser la source dans VSS  **************
*********************** Le service d'authentification risque de ne plus fonctionner correctement sinon **************
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_AuthentifierUsager]
	@iUserId					INT,
	@vbMotPasse					varbinary(100),
	@vbCleConfirmationMD5		varbinary(100) = null
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	--
	-- Initialisation
	--
	Declare @msg varchar(max)
	
	-- Parametre
	Declare 
		@Succes int,
		@Result int,
		@NbMaxTentative_Desactivation int,
		@NbMaxTentative_DesactivationSAC int,
		@DelaisAttente_min int,
		@MessageAnglais varchar(max),						-- Message a retourner et afficher a l'utilisateur
		@MessageFrancais varchar(max),						-- Message a retourner et afficher a l'utilisateur
		@NoticeAnglais varchar(max),						-- Message a retourner et afficher a l'utilisateur
		@NoticeFrancais varchar(max),						-- Message a retourner et afficher a l'utilisateur
		@EtatTypo int										-- Etat 0,1,5
		
	-- Resultat a retourner si Success
	Create table #Result(		
		Nom varchar(50),				
		Prenom varchar(35),
		No_Civique VARCHAR(10) NULL,
		Rue VARCHAR(75) NULL,
		No_Appartement VARCHAR(10) NULL,
		Type_Rue VARCHAR(20) NULL,
		Case_Postale VARCHAR(10) NULL,	
		Route_Rurale VARCHAR(10) NULL,	
		Ville varchar(100),				
		Province varchar(75),			
		CodePostal varchar(10),		
		PaysCode varchar(4),
		Pays varchar(75),
		Courriel varchar(100),
		ConsentementSouscripteur bit,
		ConsentementBeneficiaire bit,
		TelMaison varchar(37),
		TelBureau varchar(37),
		NomRepresentant varchar(50),
		PrenomRepresentant varchar(35),
		TelRepresentant varchar(37),
		CourrielRepresentant varchar(100),
		type_humain varchar(2),
		TelMobile varchar(37)
		)
	
	select @EtatTypo = 0			
	select @Succes = min(id) from syscomments where object_name(id) = 'psGENE_AuthentifierUsager'
	select @Result = 0			-- Retourne echec par defaut
	
	select @NbMaxTentative_Desactivation = dbo.fnGENE_ObtenirParametre('GENE_AUTHENTIFICATION_MAX_TENTATIVE', NULL,NULL,NULL,NULL,NULL,NULL)
	select @NbMaxTentative_DesactivationSAC = dbo.fnGENE_ObtenirParametre('GENE_AUTHENTIFICATION_MAX_TENTATIVE_SAC', NULL,NULL,NULL,NULL,NULL,NULL)
	select @DelaisAttente_min = dbo.fnGENE_ObtenirParametre('GENE_AUTHENTIFICATION_DELAI_ATTENTE_REACTIVATION_COMPTE', NULL,NULL,NULL,NULL,NULL,NULL)

	-- Usager info
	Declare 
		@vbMotPasse_Courrant varbinary(100),
		@iEtat_Courrant int,
		@dtDernierAcces_Courrant datetime,
		@iCompteurEssais_Courrant int,
		@vbCleConfirmationMD5_Courrant varbinary(100)
		 
	select 
		@vbMotPasse_Courrant = vbMotPasse,
		@iEtat_Courrant = iEtat,
		@dtDernierAcces_Courrant = dtDernierAcces,
		@iCompteurEssais_Courrant = iCompteurEssais,
		@vbCleConfirmationMD5_Courrant = vbCleConfirmationMD5
	from 
		tblGENE_PortailAuthentification
	where 
		iUserId = @iUserId
		
	--
	-- Validation
	--	
	
	-- Si le compte est inexistants, alors remappe vers l'etat virtuel 6 - Compte inexistants
	set @iEtat_Courrant = isnull(@iEtat_Courrant, 6)

	-- Verifie que l'on demande soit une authentification par mot de passe ou une confirmation par Cle md5
	if @vbMotPasse is null and	@vbCleConfirmationMD5 is null
	BEGIN
		RAISERROR('Un mot de passe ou une cle de confirmation doit obligatoirement être spécifié',15,1)
		RETURN 210
	END

	SELECT @NoticeFrancais = ''
	SELECT @NoticeAnglais = ''

	-- Calculer message si pas en mode confirmation de cle md5
	if 	@vbCleConfirmationMD5 is null
		exec psGENE_RetournerMessageAccueil @iUserId, @MessageAnglais output, @MessageFrancais output,@NoticeAnglais output, @NoticeFrancais output
		
	SELECT @EtatTypo = 
		Case 
			when @iEtat_Courrant in (5) then 1
		else 
			0
		end
		
	if @iEtat_Courrant not in (5,1)	and @vbMotPasse is not null	-- Actif ou desactive temporairement et Authentification par mot de passe demandée
	BEGIN
		select @Result as Resultat, @MessageFrancais as MessageFrancais, @MessageAnglais as MessageAnglais, @NoticeFrancais as NoticeFrancais, @NoticeAnglais as NoticeAnglais, @EtatTypo as Etat
		select * from #Result
		
		-- RAISERROR(@MessageFrancais,15,1)
		RETURN 300 + @iEtat_Courrant
	END	

	--
	-- Principal
	--

	if @vbCleConfirmationMD5 is not null
	BEGIN
		-- Mode confirmation par clé MD5
		--------------------------------

		if @vbCleConfirmationMD5_Courrant = 0x0
		BEGIN
			RAISERROR('Aucune confirmation par cle MD5 n''est necessaire',15,1)
			RETURN 220				
		END
		
		if @vbCleConfirmationMD5 = @vbCleConfirmationMD5_Courrant 
		BEGIN
			Set @Result = @Succes
			set @iEtat_Courrant = 5
			set @iCompteurEssais_Courrant = 0
			set @vbCleConfirmationMD5 = 0x0
		END
		ELSE BEGIN
			RAISERROR('La cle de confirmation MD5 ne correspond pas',15,1)
			RETURN 230	
		END
	END
	ELSE BEGIN
		
		-- Mode Authentification par mot de passe
		-----------------------------------------
		
		-- Si etat usager a été reinitialisé par SAC mais pas le compteur alors ajuster le compteur
		if @iEtat_Courrant in (5) and @iCompteurEssais_Courrant >= @NbMaxTentative_Desactivation
		BEGIN
			set @iCompteurEssais_Courrant = 0
		END
		
		-- Si Usager est desactivé temporairement et le temps attente dépassé
		if  @iEtat_Courrant = 1 and datediff(mi,@dtDernierAcces_Courrant,getdate()) > @DelaisAttente_min 
		BEGIN
			-- On redonne 3 essais
			set @iEtat_Courrant = 5
			set @iCompteurEssais_Courrant = 0
		END
		
		-- Verifier si l'usager a le droit encore a une chance
		if	@iEtat_Courrant in (5)																			-- Usager actif		
		BEGIN
			-- Tentative de connection authorisée

			if @vbMotPasse = @vbMotPasse_Courrant
			BEGIN
				-- Authentification réussi
				SELECT
					@Result = @Succes,
					@iCompteurEssais_Courrant = 0,
					@iEtat_Courrant = 5,							-- Actif
					@dtDernierAcces_Courrant = getdate()

				-- Retourne les resultats de l'usager					
				insert into #Result
				select
					hu.lastname,
					hu.firstname,
					r.vcNo_Civique,
					r.vcRue,
					r.vcNo_Appartement,
					r.vcType_Rue,
					r.vcCase_Postale,
					r.vcRoute_Rurale,		
					ad.city,
					ad.StateName,
					Case when co.CountryName = 'Canada' then left(REPLACE(ad.zipcode,' ', ''),3)+ ' ' + right(REPLACE(ad.zipcode,' ', ''),3) else ad.zipcode end,
					rtrim(ad.CountryId),
					co.CountryName,
					ad.email,
					Su.bReleve_Papier,
					Be.bReleve_Papier,
					Phone1 = CASE when ad.CountryId IN ('CAN','USA') then '(' + SUBSTRING(ad.Phone1,1,3) + ') ' + SUBSTRING(ad.Phone1,4,3) + '-' + SUBSTRING(ad.Phone1,7,4) + CASE WHEN len(ad.Phone1) > 10 THEN ' Ext: ' + SUBSTRING(ad.Phone1,11,20) ELSE '' END else ad.Phone1 end,
					Phone2 = CASE when ad.CountryId IN ('CAN','USA') then '(' + SUBSTRING(ad.Phone2,1,3) + ') ' + SUBSTRING(ad.Phone2,4,3) + '-' + SUBSTRING(ad.Phone2,7,4) + CASE WHEN len(ad.Phone2) > 10 THEN ' Ext: ' + SUBSTRING(ad.Phone2,11,20) ELSE '' END else ad.Phone2 end,
     				vcNomRep = CASE WHEN ISNULL(Rep.vcPrenomRep,'') IN ('Siège', 'Head', 'CGL') AND ISNULL(Rep.vcNomRep,'') IN ('Social', 'Office', 'Groupe') THEN '' ELSE Rep.vcNomRep END,
					vcPrenomRep = CASE WHEN ISNULL(Rep.vcPrenomRep,'') IN ('Siège', 'Head', 'CGL') AND ISNULL(Rep.vcNomRep,'') IN ('Social', 'Office', 'Groupe') THEN '' ELSE Rep.vcPrenomRep END,
					Phone1 = CASE WHEN ISNULL(Rep.vcPrenomRep,'') IN ('Siège', 'Head', 'CGL') AND ISNULL(Rep.vcNomRep,'') IN ('Social', 'Office', 'Groupe')
							 THEN ''
							 ELSE CASE when ad.CountryId IN ('CAN','USA') then '(' + SUBSTRING(Rep.vcTelRep,1,3) + ') ' + SUBSTRING(Rep.vcTelRep,4,3) + '-' + SUBSTRING(Rep.vcTelRep,7,4) + CASE WHEN len(Rep.vcTelRep) > 10 THEN ' Ext: ' + SUBSTRING(Rep.vcTelRep,11,20) ELSE '' END else Rep.vcTelRep end
							 END,
					email =	CASE WHEN ISNULL(Rep.vcPrenomRep,'') IN ('Siège', 'Head', 'CGL') AND ISNULL(Rep.vcNomRep,'') IN ('Social', 'Office', 'Groupe')
									THEN ''
									ELSE Rep.vcCourrielRep 
									END,
					type_humain = CASE 
							WHEN Su.SubscriberId IS NOT NULL THEN 'S' 
							WHEN Be.BeneficiaryId IS NOT NULL THEN 'B'
							ELSE 'ND'
							END,
					Mobile = CASE when ad.CountryId IN ('CAN','USA') then '(' + SUBSTRING(ad.Mobile,1,3) + ') ' + SUBSTRING(ad.Mobile,4,3) + '-' + SUBSTRING(ad.Mobile,7,4) + CASE WHEN len(ad.Mobile) > 10 THEN ' Ext: ' + SUBSTRING(ad.Mobile,11,20) ELSE '' END else ad.Mobile end
				FROM dbo.mo_Human Hu
					left JOIN dbo.Mo_Adr ad on Hu.AdrId = ad.adrId
					left join mo_Country co on ad.CountryId = co.CountryId
					left JOIN dbo.Un_Subscriber Su on su.SubscriberId = hu.HumanId 
					left JOIN dbo.Un_Beneficiary Be on Be.BeneficiaryId = hu.humanId
					outer apply (select max(ConventionId) as ConventionID FROM dbo.Un_Convention unCon where unCon.subscriberid = su.SubscriberId) Con
					outer apply fntCONV_ObtenirRepresentantSouscripteur(Con.ConventionId) Rep
					CROSS APPLY dbo.fntGENE_ObtenirElementsAdresse(ad.address,CASE when ad.CountryId IN ('CAN','USA') then 1 else 0 end) AS r
				where
					hu.humanid = @iUserId
							
			END
			ELSE BEGIN
				-- Echec authentification
				SELECT
					@iCompteurEssais_Courrant = @iCompteurEssais_Courrant + 1,
					@dtDernierAcces_Courrant = getdate(),
					@MessageFrancais = 'Echec d''authentification, le mot de passe spécifié est invalide', 
					@MessageAnglais = 'Authentication failed, the specified password is invalid'
					
				if @iCompteurEssais_Courrant >= @NbMaxTentative_Desactivation
					set @iEtat_Courrant = 1

				if @iCompteurEssais_Courrant >= @NbMaxTentative_DesactivationSAC
					set @iEtat_Courrant = 2
							
			END

		END	
		ELSE BEGIN
			-- Tentative de connection non authorisé

			set @iCompteurEssais_Courrant = @iCompteurEssais_Courrant + 1
			set @dtDernierAcces_Courrant = getdate()
			
			-- Changer le status si le nb max de tentative est depasse pour reactivation par le SAC
			if @iCompteurEssais_Courrant >= @NbMaxTentative_DesactivationSAC
				set @iEtat_Courrant = 2
			
		END
	END
	
	-- Mise a jour des stats de connection
	update tblGENE_PortailAuthentification	
	set 
		iCompteurEssais = @iCompteurEssais_Courrant,
		dtDernierAcces = @dtDernierAcces_Courrant,
		iEtat = @iEtat_Courrant,
		vbCleConfirmationMD5 = isnull(@vbCleConfirmationMD5,vbCleConfirmationMD5)
	where 
		iUserId = @iUserId
	  
	select @Result as Resultat, @MessageFrancais as MessageFrancais, @MessageAnglais as MessageAnglais, @NoticeFrancais as NoticeFrancais, @NoticeAnglais as NoticeAnglais, @EtatTypo as Etat
	select * from #Result
END

/*
--
-- MAJ du parametre afin que l'application connaisse la valeur Succes de retour de la SP
--
DECLARE @Succes int,
		@vcSucces varchar(20)
select @Succes = min(id) from syscomments where object_name(id) = 'psGENE_AuthentifierUsager'

select @vcSucces = cast(@Succes as varchar)

EXEC dbo.psGENE_ModifierParametre 'GENE_AUTHENTIFICATION_VALEUR_RETOUR_SUCCES', NULL,  NULL,  NULL,  NULL,  NULL,  NULL, @vcSucces

select @vcSucces as SuccesValeurRetour, dbo.fnGENE_ObtenirParametre('GENE_AUTHENTIFICATION_VALEUR_RETOUR_SUCCES', NULL,NULL,NULL,NULL,NULL,NULL) as SuccesValeurRetourParametre
select dbo.fnGENE_ObtenirParametre('GENE_AUTHENTIFICATION_VALEUR_RETOUR_SUCCES', NULL,NULL,NULL,NULL,NULL,NULL)
GO
*/


