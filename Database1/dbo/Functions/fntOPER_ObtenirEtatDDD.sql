/****************************************************************************************************
Code de service		:		fntOPER_ObtenirEtatDDD
Nom du service		:		Obtenir l'état d'une ou totue les DDD 
But					:		Obtenir l'état d'une ou totue les DDD 
Facette				:		OPER
Reférence			:		
Parametres d'entrée :	Parametres					Description                                                     Obligatoir
                        ----------                  ----------------                                                --------------                       
                        iIDDDD						Id de la DDD ou NULL pour toutes les DDD						Oui
						dtDateTo					en date du														Oui

Exemple d'appel:
                SELECT * FROM  DBO.fntOPER_ObtenirEtatDDD (100034, GETDATE())
				SELECT * FROM  DBO.fntOPER_ObtenirEtatDDD (NULL, GETDATE())

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
                       @tEtatDDD			        id				                            Id de la DDD
					   @tEtatDDD			        Etat				                        État de la DDD en date demandée
					   @tEtatDDD			        DateEtat				                    Date de l'état de la DDD
					   @tEtatDDD			        Montant				                        Montant de la DDD
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2014-09-24					Donald Huppé							Création de la fonction 
						2014-11-05					Donald Huppé							Comparer les dates en enlevant les HH:mm:ss
						2014-11-06					Donald Huppé							Gestion des rejet vs confirmation
                        2015-09-28					Donald Huppé							Calcul de DateEtat en date demandée
						2017-12-11					Stephane Roussel						Ajout de la version anglaise (EtatEN)
                        2017-12-21                  Pierre-Luc Simard                       Espace ajouté pour EnAttente et EnTraitement
                        2017-12-27                  Sébastien Rodrigue                      Ajout de « - DnD » à certaine description
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fntOPER_ObtenirEtatDDD] 
(	
	@iIDDDD		INT = null,
	@dtDateTo	DATETIME
)
RETURNS @tEtatDDD 
	TABLE (
			id					INT,
			Etat				Varchar(15),
			EtatEN				Varchar(15),
			DateEtat			DATETIME,
			Montant				MONEY
		  )
BEGIN

	insert into @tEtatDDD
	select DISTINCT
		ddd.id,
		Etat = case 

			-- Vu qu'on recoit @dtDateTo en format aaaa-mm-jj hh:mm:ss, on fait < ou lieu de <=
			-- Car on recoit soit un GetDate avec unheure de la journée ou une date à minuit le soir

			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateEffetRetourne, 120), 10),'9999-12-31')	<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Refusée - DnD'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateDecaissement, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Décaissée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateRejete, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Rejetée - DnD'

			-- S'il y a une date de rejet on fait comme si DateConfirmation est NULL
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	and ddd.DateRejete is null	then 'Confirmée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	and ddd.DateRejete is not null	then 'Rejetée'

			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateTransmission, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'En traitement'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateAnnule, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Annulée - DnD'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'En attente'
			else 'ND'
			end,
		EtatEN = case 
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateEffetRetourne, 120), 10),'9999-12-31')	<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Refused - DnD'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateDecaissement, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Withdrawn'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateRejete, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Rejected - DnD'

			-- S'il y a une date de rejet on fait comme si DateConfirmation est NULL
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	and ddd.DateRejete is null	then 'Confirmed'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	and ddd.DateRejete is not null	then 'Rejected'

			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateTransmission, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Processing'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateAnnule, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Canceled - DnD'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)		then 'Pending'
			else 'ND'
			end,			
		DateEtat = CASE
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateEffetRetourne, 120), 10),'9999-12-31')	<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateEffetRetourne
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateDecaissement, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateDecaissement
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateRejete, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateRejete
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateConfirmation
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateTransmission, 120), 10),'9999-12-31')		<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateTransmission
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateAnnule, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateAnnule
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10),'9999-12-31')			<= LEFT(CONVERT(VARCHAR, @dtDateTo,120), 10)	then ddd.DateCreation
			else '1900-01-01'
			end,
		ddd.Montant
	from DecaissementDepotDirect ddd
	WHERE DDD.ID = @iIDDDD or @iIDDDD is null

	RETURN
END